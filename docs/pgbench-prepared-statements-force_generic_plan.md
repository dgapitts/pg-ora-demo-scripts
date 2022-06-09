## Sumary - prepared statements around partitioning faster with `plan_cache_mode` = `force_generic_plan`


*Note* 
* also worth reviewing the *ealier* anaylsis [Prepared statements can be a lot faster but issues around partitioning](docs/pgbench-prepared-statements.md)
* this analysis is then also *continued* here [Prepared statements, partitioning pruning and plan_cache_mode](docs/Demo10-prepared_statements-partitioning_pruning-and-plan_cache_mode.md), but focusing on the actual execution plans for individual queries i.e. do we see partition pruning and what happens to prepare times.




Again following this postgres blog post["Postgres: on performance of prepared statements with partitioning"]](https://amitlan.com/2022/05/16/param-query-partition-woes.html):

> Along with the patch I mentioned above which improves the execution performance of generic plans containing partitions, we will also need to fix things such that generic plans don’t appear more expensive than custom plans to the plan caching logic for it to choose the former. Till that’s also fixed, users will need to use plan_cache_mode = force_generic_plan to have plan caching for partitions.

Rerunning test after  switch `plan_cache_mode` from `auto` (default) to `force_generic_plan` and now prepared statements are roughly x2 faster.


##  switch `plan_cache_mode` from `auto` (default) to `force_generic_plan` 


Appended plan_cache_mode to postgresql.conf
```
[pg13-db1:postgres:~] # tail -1 ./13/data/postgresql.conf
plan_cache_mode = force_generic_plan
```

the default value is auto
```
[local] postgres@postgres=# show plan_cache_mode;
┌─────────────────┐
│ plan_cache_mode │
├─────────────────┤
│ auto            │
└─────────────────┘
(1 row)
```

and after running `pg_reload_conf()` we switch `plan_cache_mode` from `auto` (default) to `force_generic_plan`

```
[local] postgres@postgres=# select pg_reload_conf();
┌────────────────┐
│ pg_reload_conf │
├────────────────┤
│ t              │
└────────────────┘
(1 row)

Time: 6.003 ms
[local] postgres@postgres=# show plan_cache_mode;
┌────────────────────┐
│  plan_cache_mode   │
├────────────────────┤
│ force_generic_plan │
└────────────────────┘
(1 row)
```




## 10 partitions - rerunning test after  switch `plan_cache_mode` from `auto` (default) to `force_generic_plan`

### setup




```
[pg13-db1:postgres:~] # pgbench -i --partitions=10 -s 5 --partition-method=range
dropping old tables...
creating tables...
creating 10 partitions...
generating data (client-side)...
500000 of 500000 tuples (100%) done (elapsed 1.25 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.18 s (drop tables 0.07 s, create tables 0.03 s, client-side generate 1.36 s, vacuum 0.44 s, primary keys 0.28 s).
```



### with protocol=prepared tps = 19037 (excluding connections establishing)
```
[pg13-db1:postgres:~] # pgbench -S -t 100000 --protocol=prepared
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 10
query mode: prepared
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.053 ms
tps = 19015.941199 (including connections establishing)
tps = 19037.464004 (excluding connections establishing)
```

### without protocol=prepared tps = 10316 (excluding connections establishing)


```
[pg13-db1:postgres:~] # pgbench -S -t 100000
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 10
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.099 ms
tps = 10130.977490 (including connections establishing)
tps = 10137.362388 (excluding connections establishing)
```


