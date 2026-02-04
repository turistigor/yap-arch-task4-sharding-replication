# Методы перераспределения шардированных данных в MongoDB
- Включение процесса, отвечающего за автоматическую балансировку шардов
    ```javascript
    sh.startBalancer();  // sh.setBalancerState(true)

    // Дополнительные команды
    sh.getBalancerState()  // true если включен
    sh.isBalancerRunning() // true если балансировка идет сейчас
    ```
- Ручная балансировка  
    - Переместить чанки вручную
        ```javascript
        sh.moveChunk("<db_name>.<collection>", { shard_key_field: <value> }, "target-shard-name")
        ```
    - Разделить чанки вручную
        ```javascript
        sh.splitAt("<db_name>.<collection>", { shard_key_field: "<hash_value>" });
        sh.splitAt("<db_name>.<collection>", { shard_key_field: "<hash_value2>" });
        ```
    - Добавить новый шард
        ```javascript
        sh.addShard("<name>/<host>:<port>")
        ```
        В этом случае балансировка будет произведена автоматически.
    - Изменить размер чанка для более частой автобалансировки
        ```javascript
        db.settings.updateOne(
            { _id: "chunksize" },
            { $set: { value: 64 } },  // 128MB (def) -> 64MB
            { upsert: true }
        );
        ```
    - Дополнение ключа шардирования (для случая высокой гранулярности):
        ```javascript
        db.adminCommand({
            refineCollectionShardKey: "<db_name>.<collection>",
            key: { current_shard_key_field: 1, additional_shard_key_field: 1 }
        });
        ```
    - Смена ключа шардирования
        ```javascript
        db.adminCommand({
            reshardCollection: "<db_name>.<collection>",
            key: { new_shard_key_field: "<hash_type>" }
        });
        ```
