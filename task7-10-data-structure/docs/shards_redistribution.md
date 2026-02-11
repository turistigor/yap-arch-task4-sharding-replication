# Методы перераспределения шардированных данных в MongoDB

## Автоматическая балансировка

### Основные команды управления

```javascript
sh.startBalancer();  // sh.setBalancerState(true)

// Дополнительные команды
sh.getBalancerState()  // true если включен
sh.isBalancerRunning() // true если балансировка идет сейчас
```

### Zoned tag sharding
Механизм хорошо подходит для создания условий равномерного распределения данных. Для перераспределения существующих данных подходит хуже так как может приводить к дублированию данных на разных шардах.
```javascript
// Создать тэги для шардов
sh.addShardTag("<shard1_name>" , "<tag1>");
sh.addShardTag("<shard2_name>" , "<tag2>");

// Закрепить диапазоны хэшей за тегами
sh.addTagRange("<db_name>.<collection>", {"<shard_key>": "<range1_min>"}, {"<shard_key>": "<range1_max>"}, "<tag1>");
sh.addTagRange("<db_name>.<collection>", {"<shard_key>": "<range2_min>"}, {"<shard_key>": "<range2_max>"}, "<tag2>");

// Добавить данные в коллекцию
for(var i = 0; i < 1000; i++) db.collection.insert({/*document content*/});

// Наблюдать распределение в соответствии с диапазонами тэгов
db.helloDoc.getShardDistribution()

// В случае появления дополнительных данных расширить набор диапазонов
sh.updateZoneKeyRange("<db_name>.<collection>", {"<shard_key>": "<range3_min>"}, {"<shard_key>": "<range3_max>"}, "<tag1>");
sh.updateZoneKeyRange("<db_name>.<collection>", {"<shard_key>": "<range4_min>"}, {"<shard_key>": "<range4_max>"}, "<tag1>");

// Добавить данные в коллекцию
for(var i = 0; i < 1000; i++) db.collection.insert({/*document content*/});

// Наблюдать распределение в соответствии с диапазонами тэгов
db.helloDoc.getShardDistribution();

// Добавление нового шарда с выделением диапазона для него
sh.addShard("<new_shard_name>/<new_shard_host>:<new_shard_port>");
sh.addShardTag("<new_shard_name>" , "<new_shard_tag>");
sh.addTagRange("<db_name>.<collection>", {"<shard_key>": "<new_range_min>"}, {"<shard_key>": "<new_range_max>"}, "<new_shard_tag>");

// Добавить данные в коллекцию
for(var i = 0; i < 1000; i++) db.collection.insert({/*document content*/});

// Наблюдать распределение в соответствии с диапазонами тэгов
db.helloDoc.getShardDistribution();
```

## Ручная балансировка  

### Переместить чанки вручную
```javascript
sh.moveChunk("<db_name>.<collection>", { shard_key_field: <value> }, "target-shard-name")
```

### Разделить чанки вручную
```javascript
sh.splitAt("<db_name>.<collection>", { shard_key_field: "<hash_value>" });
sh.splitAt("<db_name>.<collection>", { shard_key_field: "<hash_value2>" });
```

### Добавить новый шард
```javascript
sh.addShard("<name>/<host>:<port>")
```
В этом случае балансировка будет произведена автоматически.

### Изменить размер чанка для более частой автобалансировки
```javascript
db.settings.updateOne(
    { _id: "chunksize" },
    { $set: { value: 64 } },  // 128MB (def) -> 64MB
    { upsert: true }
);
```

### Дополнение ключа шардирования (для случая высокой гранулярности):
```javascript
db.adminCommand({
    refineCollectionShardKey: "<db_name>.<collection>",
    key: { current_shard_key_field: 1, additional_shard_key_field: 1 }
});
```

### Смена ключа шардирования
```javascript
db.adminCommand({
    reshardCollection: "<db_name>.<collection>",
    key: { new_shard_key_field: "<hash_type>" }
});
```
