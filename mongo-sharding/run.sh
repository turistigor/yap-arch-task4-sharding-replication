# !#/bin/bash

docker-compose up -d config_srv shard1 shard2

docker exec config_srv mongosh --port 27017 --eval '
    rs.initiate(
        {
            _id : "config_server",
            configsvr: true,
            members: [
                {_id : 0, host : "config_srv:27017" }
            ]
        }
    );
'

docker exec shard1 mongosh --port 27018 --eval '
    rs.initiate(
        {
            _id : "shard1",
            members: [
                { _id : 0, host : "shard1:27018" },
            ]
        }
    );
'

docker exec shard2 mongosh --port 27019 --eval '
    rs.initiate(
        {
            _id : "shard2",
            members: [
                { _id : 0, host : "shard2:27019" },
            ]
        }
    );
'

docker-compose up -d mongos_router
sleep 3

docker exec mongos_router mongosh --port 27020 --eval '
    sh.addShard("shard1/shard1:27018");
    sh.addShard("shard2/shard2:27019");
    sh.enableSharding("somedb");
    sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
'

docker-compose up -d pymongo_api

read -p "Do you want to fill the database (Y/n)?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
then
    docker cp ./fill_db.js mongos_router:/tmp/fill_db.js
    docker exec mongos_router bash -c "mongosh --port 27020 < /tmp/fill_db.js"
fi
