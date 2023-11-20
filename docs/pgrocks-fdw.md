##  Postgres with RocksDB pgrocks-fdw

This [pgrocks-fdw project](https://github.com/vidardb/pgrocks-fdw/tree/master) sounds interesting
> Bring RocksDB to PostgreSQL as an extension. It is the first foreign data wrapper (FDW) that introduces LSM-tree into PostgreSQL. The underneath storage engine can be RocksDB. The FDW also serves for VidarDB engine, a versatile storage engine for various workloads. See the link for more info about VidarDB engine

### Base setup via Docker

The only issue with the [release notes here](https://github.com/vidardb/pgrocks-fdw/blob/master/docker_image/README.md) was the wrong/old version number (6.2.4 and not 6.11.4)
```
[~] # docker run -d --name postgresql -p 5432:5432 vidardb/postgresql:rocksdb-6.2.4
fdcf01e14955c6c5a199891b3207a3d8e9abe7051164a5cd6a0ee9401fc049f0
```

then everything was fine 

```
[~] # docker ps
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS          PORTS                                       NAMES
fdcf01e14955   vidardb/postgresql:rocksdb-6.2.4   "docker-entrypoint.s…"   14 seconds ago   Up 13 seconds   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   postgresql
[~] # docker exec -it postgresql sh -c 'psql -h 127.0.0.1 -p 5432 -U postgres'
psql (12.4 (Debian 12.4-1.pgdg100+1))
Type "help" for help.

postgres=# 
```

