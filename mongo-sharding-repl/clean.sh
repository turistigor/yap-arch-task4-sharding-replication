docker-compose down
docker volume rm \
    mongo-sharding-repl_shard1-replica1-data \
    mongo-sharding-repl_shard1-replica2-data \
    mongo-sharding-repl_shard1-replica3-data \
    mongo-sharding-repl_shard2-replica1-data \
    mongo-sharding-repl_shard2-replica2-data \
    mongo-sharding-repl_shard2-replica3-data
