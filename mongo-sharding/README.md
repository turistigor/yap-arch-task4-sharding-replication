# Конды для настройки шардирования и запуска системы

Нижеприведенная последовательность команд составлена в том числе для изучения с контролем изменений и результатов отдельных команд. Для быстроты можно воспользоваться [скриптом](run.sh), содержащим необходимый минимум. В нем нет вывода и проверок успешности операций. При необходимости можно воспользоваться [скриптом очистки](clean.sh) и начать все заново.

- Создание и запуск сервиса конфигураций и двух шардов.
```bash
docker-compose up -d config_srv shard1 shard2
```

- Настройка сервиса конфигураций (с командами проверки результатов)
```bash
docker exec -it config_srv mongosh --port 27017
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received

rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "config_srv:27017" }
    ]
  }
);
rs.status();  # replica set description with the member "config_server".
exit();
```

- Настройка шардов (с командами проверки результатов)
```bash
docker exec -it shard1 mongosh --port 27018
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received

rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
      ]
    }
);
rs.status();  # replica set description with the member "shard1".
exit();

docker exec -it shard2 mongosh --port 27019
rs.status();  # MongoServerError[NotYetInitialized]: no replset config has been received

rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27019" },
      ]
    }
);
rs.status();  # replica set description with the member "shard2".
exit();
```

- Запуск и настройка роутера (с командами проверки результатов)

```bash
docker-compose up -d mongos_router
docker exec -it mongos_router mongosh --port 27020

sh.status();  # Много всего, важно: "shards[]"
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
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

- Проверка распределения данных по шардам (нет в скрипте)
```bash
docker exec -it shard1 mongosh -port 27018
use somedb;
db.helloDoc.countDocuments();  # X1 - часть от общего количества документов в mongos_router ()

docker exec -it shard2 mongosh -port 27019
use somedb;
db.helloDoc.countDocuments();  # X2 - часть от общего количества документов в mongos_router

# X1 + X2 = N + 1000
```
