# Способы получения метрик шардов 

- Расход памяти  
    Можно получить при помощи MongoDB API следующим образом:

    ```javascript
    const shardConn = new Mongo("<shard_host>:<shard_port>");
    const shardDB = shardConn.getDB("<db_name>");
    const status = shardDB.serverStatus();

    const shard_volume = status.mem.resident;
    ```
    Полученное значение - объём физической памяти шарда в байтах.

- Количество операций  
    Можно получить при помощи MongoDB API следующим образом:

    ```javascript
    const shardConn = new Mongo("<shard_host>:<shard_port>");
    const shardDB = shardConn.getDB("<db_name>");
    const status = shardDB.serverStatus();

    var shard_reqs = status.opcounters.command + 
        status.opcounters.query + 
        status.opcounters.update + 
        status.opcounters.delete + 
        status.opcounters.insert;
    ```
    Полученное значение - общее количество разных операция, выполненных указанным шардом.

- Использование процессора  
    MongoDB API не предоставляет простого способа получить интересующие данные.  
    Однако, собирая данные об использовании процессора контейнерами шардов, можно вычислить интересующие метрики.
    ```bash
    docker stats --format "{{.Name}}: {{.CPUPerc}}" <shard1> <shard2>
    ```

# Дополнительные способы проведения анализа
- Распределение ресурсов между шардами
    ```javascript
    db.collection.getShardDistribution();
    sh.status();
    ```
- Текущие выполняемые операции
    ```javascript
    db.currentOp();
    ```
