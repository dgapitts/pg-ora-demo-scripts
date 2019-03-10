## Background

The main setup instructions for pg_hint_plan : http://pghintplan.osdn.jp/pg_hint_plan.html

Although my setup is part of the https://github.com/ossc-db/pg_plan_advsr  
   
## Step one - download and unpack tar files as postgres

I've scripted the initial download to be run 

```
cd ~
mkdir install_pg_plan_advsr
cd install_pg_plan_advsr
wget https://github.com/ossc-db/pg_hint_plan/archive/REL10_1_3_2.tar.gz
wget https://github.com/ossc-db/pg_store_plans/archive/1.3.tar.gz
git clone https://github.com/ossc-db/pg_plan_advsr.git pg_plan_advsr
tar xvzf REL10_1_3_2.tar.gz
tar xvzf 1.3.tar.gz
cp pg_hint_plan-REL10_1_3_2/pg_stat_statements.c pg_plan_advsr/
cp pg_hint_plan-REL10_1_3_2/normalize_query.h pg_plan_advsr/
cp pg_store_plans-1.3/pgsp_json*.[ch] pg_plan_advsr/
cd pg_hint_plan-REL10_1_3_2
```


## Setup part two - as root for `make && make install`

you need to do this as root

```
[root@pg10centos7 pg_hint_plan-REL10_1_3_2]# PGDATA=/var/lib/pgsql/10/data
[root@pg10centos7 pg_hint_plan-REL10_1_3_2]# PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/pgsql-10/bin
[root@pg10centos7 pg_hint_plan-REL10_1_3_2]# make && make install
make: Nothing to be done for `all'.
/usr/bin/mkdir -p '/usr/pgsql-10/share/extension'
/usr/bin/mkdir -p '/usr/pgsql-10/share/extension'
/usr/bin/mkdir -p '/usr/pgsql-10/lib'
/usr/bin/install -c -m 644 .//pg_hint_plan.control '/usr/pgsql-10/share/extension/'
/usr/bin/install -c -m 644 .//pg_hint_plan--1.3.2.sql .//pg_hint_plan--1.3.0--1.3.1.sql .//pg_hint_plan--1.3.1--1.3.2.sql  '/usr/pgsql-10/share/extension/'
/usr/bin/install -c -m 755  pg_hint_plan.so '/usr/pgsql-10/lib/'
```

## Step 3 - back as postgres run `LOAD 'pg_hint_plan'`

```
[pg10centos7:postgres:~/install_pg_plan_advsr/pg_hint_plan-REL10_1_3_2] # psql
psql (10.7)
Type "help" for help.

postgres=# LOAD 'pg_hint_plan';
LOAD
```


## Testing

Setup table t1 
```
create table t1 (a int, b int);
insert into t1 (select a, random() * 1000 from generate_series(0, 999999) a);
create index i_t1_a on t1 (a);
analyze t1;
select * from t1 limit 5;
```

Setup table t2
```
create table t2 (a int, b int);
insert into t2 (select a, random() * 1000 from generate_series(0, 999999) a);
create index i_t2_a on t2 (a);
analyze t1;
```


Now testing without index hints:
```                              ^
postgres=# explain SELECT * FROM t1 JOIN  t2 ON (t1.a = t2.a);
                               QUERY PLAN
------------------------------------------------------------------------
 Hash Join  (cost=30832.00..70728.00 rows=1000000 width=16)
   Hash Cond: (t1.a = t2.a)
   ->  Seq Scan on t1  (cost=0.00..14425.00 rows=1000000 width=8)
   ->  Hash  (cost=14425.00..14425.00 rows=1000000 width=8)
         ->  Seq Scan on t2  (cost=0.00..14425.00 rows=1000000 width=8)
(5 rows)
```

Now testing without index hints:
```
postgres=# explain analyze /*+ SeqScan(t2) IndexScan(t1 i_t1_a) */  SELECT * FROM t1 JOIN  t2 ON (t1.a = t2.a);
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=31832.00..53315.84 rows=1000000 width=16) (actual time=601.365..2807.945 rows=1000000 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Hash Join  (cost=30832.00..52315.84 rows=416667 width=16) (actual time=983.503..2233.652 rows=333333 loops=3)
         Hash Cond: (t1.a = t2.a)
         ->  Parallel Seq Scan on t1  (cost=0.00..8591.67 rows=416667 width=8) (actual time=0.055..98.664 rows=333333 loops=3)
         ->  Hash  (cost=14425.00..14425.00 rows=1000000 width=8) (actual time=981.804..981.804 rows=1000000 loops=3)
               Buckets: 131072  Batches: 16  Memory Usage: 3471kB
               ->  Seq Scan on t2  (cost=0.00..14425.00 rows=1000000 width=8) (actual time=0.046..359.853 rows=1000000 loops=3)
 Planning time: 0.280 ms
 Execution time: 2888.424 ms
(11 rows)
```

although I'm not seeing much usage of index i_t1_a?


