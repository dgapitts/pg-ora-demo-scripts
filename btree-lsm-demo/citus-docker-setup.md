# Citus (columnar) docker setup

Note - full details in [citus-docker-setup.log](citus-docker-setup.log) 

Download and start `citusdata/citus:12.1 docker` image
```
docker run -d --name citus2 -p 5432:5433 -e POSTGRES_PASSWORD=mypass citusdata/citus:12.1
3aadce9fb67a0da3b449b0e46c336f2b8675172995a35510ac286bbaa57b4b74
```

connect via bash
```
docker ps
docker exec -it 3aadce9fb67a bash
```

need to set some environment variables and start postgres on port 7100

```
su - postgres
export PATH=$PATH:/usr/lib/postgresql/16/bin
initdb -D citus
echo "shared_preload_libraries = 'citus'" >> citus/postgresql.conf
pg_ctl -D citus -o "-p 9700" -l citus_logfile start
```





