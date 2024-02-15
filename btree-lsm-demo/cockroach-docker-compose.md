# CockroachDB docker compose  file - 3 node cluster with pgbench :green_heart:

This is a great find []()

I've added more details but basically to get started 

```
 docker compose -f docker-compose.yml -f docker-compose-postgresql.yml up -d --build
```

and then to see the pgclient config

```
davidpitts@Davids-MacBook-Pro cockroach-docker % docker exec -it postgresql bash
root@postgresql:/# env|grep PG
PGPORT=26000
PGUSER=root
PG_MAJOR=16
PG_VERSION=16.1-1.pgdg120+1
PGDATABASE=example
PGHOST=lb
PGDATA=/var/lib/postgresql/data
```

note the above PGHOST is `lb` which is "HAProxy acting as load balancer [for cockroachdb cluster]"


First initialize the pgbench 

```
 docker exec -it postgresql pgbench \\n    --initialize \\n    --host=${PGHOST} \\n    --username=${PGUSER} \\n    --port=${PGPORT} \\n    --no-vacuum \\n    --scale=10 \\n    --foreign-keys \\n    ${PGDATABASE}
```

We can then see the tables in the crdb `example` database

```
davidpitts@Davids-MacBook-Pro cockroach-docker % docker exec -it client cockroach sql --insecure --url 'postgres://root@lb:26000/defaultdb?sslmode=disable'
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v23.2.0-beta.1 (aarch64-unknown-linux-gnu, built 2023/11/22 19:37:50, go1.20.10 X:nocoverageredesign) (same version as client)
# Cluster ID: 92894b6f-7fa3-4f70-9f47-2963f1c404c3
#
# Enter \? for a brief introduction.
#
root@lb:26000/defaultdb> use example;
SET

Time: 2ms total (execution 1ms / network 1ms)

root@lb:26000/example> \d+
List of relations:
  Schema |         Name          | Type  | Owner |      Table       | Persistence | Access Method | Description
---------+-----------------------+-------+-------+------------------+-------------+---------------+--------------
  public | pgbench_accounts      | table | root  | NULL             | permanent   | prefix        |
  public | pgbench_accounts_pkey | index | root  | pgbench_accounts | permanent   | prefix        |
  public | pgbench_branches      | table | root  | NULL             | permanent   | prefix        |
  public | pgbench_branches_pkey | index | root  | pgbench_branches | permanent   | prefix        |
  public | pgbench_history       | table | root  | NULL             | permanent   | prefix        |
  public | pgbench_history_pkey  | index | root  | pgbench_history  | permanent   | prefix        |
  public | pgbench_tellers       | table | root  | NULL             | permanent   | prefix        |
  public | pgbench_tellers_pkey  | index | root  | pgbench_tellers  | permanent   | prefix        |
(8 rows)
root@lb:26000/example>
```



The first run (only 60 seconds)

* tps = 412.553337
* number of transactions retried: 64 (0.258%)


```
docker exec -it postgresql pgbench \\n    --host=${PGHOST} \\n    --no-vacuum \\n    --file=tpcb-original.sql@1 \\n    --client=8 \\n    --jobs=8 \\n    --username=${PGUSER} \\n    --port=${PGPORT} \\n    --scale=10 \\n    --failures-detailed \\n    --verbose-errors \\n    --max-tries=3 \\n    ${PGDATABASE} \\n    -T 60 \\n    -P 5
```


and



```
transaction type: tpcb-original.sql
scaling factor: 10
query mode: simple
number of clients: 8
number of threads: 8
maximum number of tries: 3
duration: 60 s
number of transactions actually processed: 24762
number of failed transactions: 0 (0.000%)
number of serialization failures: 0 (0.000%)
number of deadlock failures: 0 (0.000%)
number of transactions retried: 64 (0.258%)
total number of retries: 65
latency average = 19.387 ms
latency stddev = 20.572 ms
initial connection time = 2.423 ms
tps = 412.553337 (without initial connection time)
```







