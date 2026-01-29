# Настройка шардирования с репликацией и запуск системы

Нижеприведенная последовательность команд составлена в том числе для изучения с контролем изменений и результатов отдельных команд. Для быстроты можно воспользоваться [скриптом](run.sh), содержащим необходимый минимум. В нем нет вывода и проверок успешности операций. При необходимости можно воспользоваться [скриптом очистки](clean.sh) и начать все заново.

- Создание и запуск сервиса конфигураций и двух шардов.
```bash
docker-compose up -d
```

- Настройка сервиса конфигураций (с командами проверки результатов)
```bash
docker exec -it config_srv mongosh --port 27021
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received

rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "config_srv:27021" }
    ]
  }
);
rs.status();  # replica set description with the member "config_server".
exit();
```

- Настройка шардов с репликацией (с командами проверки результатов)
```bash
docker exec -it shard1_repl1 mongosh --port 27022
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_repl1:27022" },
        { _id : 1, host : "shard1_repl2:27023" },
        { _id : 2, host : "shard1_repl3:27024" }
      ]
    }
);
rs.status();  # replica set description with the member "shard1" & replicas.
exit();

docker exec -it shard2_repl1 mongosh --port 27025
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2_repl1:27025" },
        { _id : 1, host : "shard2_repl2:27026" },
        { _id : 2, host : "shard2_repl3:27027" }
      ]
    }
);
rs.status();  # replica set description with the member "shard2" & replicas.
exit();
```

- Запуск и настройка роутера (с командами проверки результатов)

```bash
docker exec -it mongos_router mongosh --port 27020

sh.status();  # Много всего, важно: "shards[]"
sh.addShard("shard1/shard1_repl1:27022");
sh.addShard("shard2/shard2_repl1:27025");
sh.status();  # Много всего, важно: "shards[{shard1}, {shard2}]"

sh.status();  # Много всего, важно: shardedDataDistribution[] и databases: ['config']
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
sh.status();  # Много всего, важно: shardedDataDistribution['somedb.helloDoc'] и databases['config', 'somedb']
exit();
```

- Заполнение БД
```bash
docker exec -it mongos_router mongosh --port 27020

use somedb
print("Documents count: " + db.helloDoc.countDocuments());  # N
for(var i = 0; i < 1000; i++) {
    db.helloDoc.insert({age:i, name:"ly"+i});
}
print("Documents count: " + db.helloDoc.countDocuments());  # N + 1000
exit();
```

- Проверка распределения данных по шардам и репликам (нет в скрипте)
```bash
docker exec -it shard1_repl1 mongosh -port 27022
use somedb;
db.helloDoc.countDocuments();  # X11 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names11 - конкретные данные в первой реплике первого шарда
exit();

docker exec -it shard1_repl2 mongosh -port 27023
use somedb;
db.helloDoc.countDocuments();  # X12, X12 == X11 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names12 == Names11 - данные во второй реплике первого шарда
exit();

docker exec -it shard1_repl3 mongosh -port 27024
use somedb;
db.helloDoc.countDocuments();  # X13, X13 == X11 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names13 == Names11 - данные в третьей реплике первого шарда
exit();

docker exec -it shard2_repl1 mongosh -port 27025
use somedb;
db.helloDoc.countDocuments();  # X21 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names21 - данные в первой реплике второго шарда
exit();

docker exec -it shard2_repl2 mongosh -port 27026
use somedb;
db.helloDoc.countDocuments();  # X22, X22 == X21 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names22 == Names21 - данные во второй реплике второго шарда
exit();

docker exec -it shard2_repl3 mongosh -port 27027
use somedb;
db.helloDoc.countDocuments();  # X23, X23 == X21 - часть от общего количества документов в mongos_router
db.helloDoc.distinct("name");  # Names23 == Names21 - данные в третьей реплике второго шарда
exit();

# X11 + X21 = N + 1000
``` -->
