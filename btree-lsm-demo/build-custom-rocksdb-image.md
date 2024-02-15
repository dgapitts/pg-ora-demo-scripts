# Build custom vidardb/postgresql:rocksdb-6.2.4_demoXX images 


## Adding customer layers to `vidardb/postgresql:rocksdb-6.2.4`

The very first layer `vidardb/postgresql:rocksdb-6.2.4_demo01` was more a personal refresher for adding a customer docker layer.

The only different is that I started a `notes.txt` in the root directory

```
root@290796457c09:/# ls -ltr notes.txt
-rw-r--r-- 1 root root 29 Jan 24 21:23 notes.txt
root@290796457c09:/# cat notes.txt
psql -d postgres -U postgres
```


## Add vi to `vidardb/postgresql:rocksdb-6.2.4_demo02` via 

```
davidpitts@Davids-MacBook-Pro docs % docker run -d --name pg_rocksdb -p 5432:5432 vidardb/postgresql:rocksdb-6.2.4_demo01
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
290796457c09efa2f6179b0c94458bc53c923ced96c3a0cb13807340a8bcb71c
davidpitts@Davids-MacBook-Pro docs % docker ps
CONTAINER ID   IMAGE                                     COMMAND                  CREATED          STATUS          PORTS                    NAMES
290796457c09   vidardb/postgresql:rocksdb-6.2.4_demo01   "docker-entrypoint.s…"   30 seconds ago   Up 29 seconds   0.0.0.0:5432->5432/tcp   pg_rocksdb
davidpitts@Davids-MacBook-Pro docs % docker exec -it 290796457c09  bash
root@290796457c09:/# vi notes.txt
bash: vi: command not found
```

As root
```
apt-get update
apt-get install vim
```

adds about 53MB
```
davidpitts@Davids-MacBook-Pro ~ % docker commit 290796457c09  vidardb/postgresql:rocksdb-6.2.4_demo02
sha256:5f748c21a7d5813f71490d416e567354b84b354b88c89600f19421613463fe96
davidpitts@Davids-MacBook-Pro ~ % docker images
REPOSITORY           TAG                    IMAGE ID       CREATED         SIZE
vidardb/postgresql   rocksdb-6.2.4_demo02   5f748c21a7d5   5 seconds ago   776MB
vidardb/postgresql   rocksdb-6.2.4_demo01   930b42e81d97   9 hours ago     723MB
postgres             16.1                   230cf55862f3   2 weeks ago     448MB
cassandra            latest                 731829ff5143   3 weeks ago     340MB
kindest/node         <none>                 6e360fda99b5   7 months ago    850MB
vidardb/postgresql   rocksdb-6.2.4          463b20a9b417   3 years ago     723MB
nuvo/docker-cqlsh    latest                 52318ea1aaa0   5 years ago     71.6MB
```

