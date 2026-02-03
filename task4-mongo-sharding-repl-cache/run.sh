#!/bin/bash

docker-compose up -d

docker exec config_srv mongosh --port 27021 --eval '
    rs.initiate(
        {
            _id : "config_server",
            configsvr: true,
            members: [
                {_id : 0, host : "config_srv:27021" }
            ]
        }
    );
'

docker exec shard1_repl1 mongosh --port 27022 --eval '
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
'

docker exec shard2_repl1 mongosh --port 27025 --eval '
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
'

sleep 3

docker exec mongos_router mongosh --port 27020 --eval '
    sh.addShard("shard1/shard1_repl1:27022");
    sh.addShard("shard2/shard2_repl1:27025");
    sh.enableSharding("somedb");
    sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
'

read -p "Do you want to fill the database (Y/n)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
then
    docker cp ./fill_db.js mongos_router:/tmp/fill_db.js
    docker exec mongos_router bash -c "mongosh --port 27020 < /tmp/fill_db.js"
fi
