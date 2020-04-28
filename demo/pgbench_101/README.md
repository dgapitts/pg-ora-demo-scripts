### setup default user and pgbench databases
```
~ $ time createdb pgbench

real	0m1.178s
user	0m0.011s
sys	0m0.010s

```

### install pgbench sample schema

```
~ $ time pgbench -i -s 3 -d pgbench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data...
100000 of 300000 tuples (33%) done (elapsed 0.33 s, remaining 0.66 s)
200000 of 300000 tuples (66%) done (elapsed 0.90 s, remaining 0.45 s)
300000 of 300000 tuples (100%) done (elapsed 1.34 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.

real	0m2.110s
user	0m0.174s
sys	0m0.029s
``` 

NB you might need to hard code pgbench path

```
~ $ time /usr/pgsql-9.6/bin/pgbench -i -s 3 -d pgbench
```
although better to append to "/usr/pgsql-9.6/bin" to the PATH.

### test connect via psql
```
psql -d pgbench
```

### sample query output on vanilla pgbench
Default four tables:
```
pgbench=# \d
             List of relations
 Schema |       Name       | Type  | Owner
--------+------------------+-------+--------
 public | pgbench_accounts | table | dpitts
 public | pgbench_branches | table | dpitts
 public | pgbench_history  | table | dpitts
 public | pgbench_tellers  | table | dpitts
(4 rows)
```
Lets start by a simple select but first only looking at the plan:
```
pgbench=# \timing on
Timing is on.
pgbench=# explain select * from pgbench_accounts;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=97)
(1 row)
Time: 3.165 ms
```
i.e. the optimizer thinks there are 300000 rows and this simple query should be "fairly cheap" i.e. optimizer cost of 
7919. This abstract cost has no direct real-world meaning but the optimizer choosed the cheapest plan (I will give further examples later which help clarify the optimizer cost model).


Running the query takes signiifcantly long (112ms) than just generating the plan
```
pgbench=# select count(*) from pgbench_accounts;
 count
--------
 300000
(1 row)

Time: 112.382 ms
```

and rerunning is faster (probably as the table blocks are not in shared buffers and fewre io calls)
```
pgbench=# select count(*) from pgbench_accounts;
 count
--------
 300000
(1 row)

Time: 29.915 ms
```

Next I'm going to rerun the query with some DBA training/debugging options i.e. *explain (analyze,buffers,verbose)*  
```
pgbench=# explain (analyze,buffers,verbose) select * from pgbench_accounts;
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=97) (actual time=0.054..51.939 rows=300000 loops=1)
   Output: aid, bid, abalance, filler
   Buffers: shared hit=2144 read=2775
 Planning time: 0.128 ms
 Execution time: 73.565 ms
(5 rows)

Time: 74.176 ms
```
and again rerunning we get similar but not identical metrics:
```
pgbench=# explain (analyze,buffers,verbose) select * from pgbench_accounts;
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=97) (actual time=0.154..37.869 rows=300000 loops=1)
   Output: aid, bid, abalance, filler
   Buffers: shared hit=2176 read=2743
 Planning time: 0.046 ms
 Execution time: 52.986 ms
(5 rows)

Time: 53.479 ms
```


### Add foreign key on pgbench_accounts(bid) to pgbench_branches - pgbench_accounts_fk_bid 
```
pgbench=# \d pgbench_accounts
              Table "public.pgbench_accounts"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 aid      | integer       |           | not null |
 bid      | integer       |           |          |
 abalance | integer       |           |          |
 filler   | character(84) |           |          |
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)

pgbench=# \d pgbench_branches
              Table "public.pgbench_branches"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 bid      | integer       |           | not null |
 bbalance | integer       |           |          |
 filler   | character(88) |           |          |
Indexes:
    "pgbench_branches_pkey" PRIMARY KEY, btree (bid)
                                             ^
pgbench=# alter table pgbench_accounts add constraint pgbench_accounts_fk_bid foreign key (bid) references pgbench_branches (bid);
ALTER TABLE
pgbench=# \d pgbench_accounts
              Table "public.pgbench_accounts"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 aid      | integer       |           | not null |
 bid      | integer       |           |          |
 abalance | integer       |           |          |
 filler   | character(84) |           |          |
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)
Foreign-key constraints:
    "pgbench_accounts_fk_bid" FOREIGN KEY (bid) REFERENCES pgbench_branches(bid)
```

### Setting account balance based off random() function

```
pgbench=# select trunc(random()*(10000*random())^2);
  trunc
----------
 14692546
(1 row)

pgbench=# \timing on
Timing is on.
pgbench=# update pgbench_accounts set abalance = trunc(random()*(10000*random())^2);
UPDATE 300000
Time: 4894.723 ms (00:04.895)
pgbench=# select * from pgbench_accounts limit 5;
 aid | bid | abalance |                                        filler
-----+-----+----------+--------------------------------------------------------------------------------------
   1 |   1 |    32375 |
   2 |   1 |     3324 |
   3 |   1 |  3482503 |
   4 |   1 |  1317682 |
   5 |   1 | 42034757 |
(5 rows)

Time: 0.409 ms
```

### Calculate sum(), avg(), stddev () for account balance
```
pgbench=# select sum(abalance),avg(abalance),stddev(abalance),bid from pgbench_accounts group by bid;
      sum      |          avg          |    stddev     | bid
---------------+-----------------------+---------------+-----
 1664430319002 | 16644303.190020000000 | 19717983.4829 |   1
 1665812580888 | 16658125.808880000000 | 19729594.0730 |   2
 1658596311769 | 16585963.117690000000 | 19684150.3421 |   3
(3 rows)

Time: 132.219 ms
```



### Add account names column (aname) and then populate randomly from {Ava,Alex,Aiden,Abigail}

https://dba.stackexchange.com/questions/55363/set-random-value-from-set

```
pgbench=# select ('[0:3]={Ava,Alex,Aiden,Abigail}'::text[])[floor(random()*4)];
 text
------
 Alex
(1 row)

Time: 1.260 ms
pgbench=# alter table pgbench_accounts add aname character(20);
ALTER TABLE
Time: 112.133 ms
pgbench=# update pgbench_accounts set aname = ('[0:3]={Ava,Alex,Aiden,Abigail}'::text[])[floor(random()*4)];
UPDATE 300000
Time: 5377.962 ms (00:05.378)
pgbench=# select aname, count(*) from pgbench_accounts group by aname;
        aname         | count
----------------------+-------
 Abigail              | 74508
 Aiden                | 74972
 Alex                 | 75376
 Ava                  | 75144
(4 rows)

Time: 138.327 ms
```


### Add branch manager names column (mname) and then populate randomly from {Bella,Brittany,Brenda,Belen}

```
pgbench=# select ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
 text
------
 Belen
(1 row)

Time: 1.260 ms
pgbench=# alter table pgbench_branches add mname character(20);
ALTER TABLE
Time: 3.988 ms
pgbench=# update pgbench_branches set mname = ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
UPDATE 3
Time: 74.112 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brittany
(3 rows)

Time: 0.294 ms
pgbench=# update pgbench_branches set mname ='Brenda' where bid=3;
UPDATE 1
Time: 1.721 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brenda
(3 rows)

Time: 0.376 ms
```


### add manager name to pgbench_branches

```
pgbench=# alter table pgbench_branches add mname character(20);
ALTER TABLE
Time: 3.988 ms
pgbench=# update pgbench_branches set mname = ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
UPDATE 3
Time: 74.112 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brittany
(3 rows)

Time: 0.294 ms
pgbench=# update pgbench_branches set mname ='Brenda' where bid=3;
UPDATE 1
Time: 1.721 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brenda
(3 rows)

Time: 0.376 ms
````



```
pgbench=# select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brenda';
   max
----------
 99852439
(1 row)

Time: 142.178 ms
pgbench=# select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Belen';
   max
----------
 99156675
(1 row)

Time: 64.182 ms
pgbench=# select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
   max
----------
 99289975
(1 row)

Time: 69.520 ms
```


### Hash Join plan with parallelization - default plan (in postgres 11.5)

```
pgbench=# explain select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                 QUERY PLAN
------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=13520.10..13520.11 rows=1 width=4)
   ->  Gather  (cost=13519.89..13520.10 rows=2 width=4)
         Workers Planned: 2
         ->  Partial Aggregate  (cost=12519.89..12519.90 rows=1 width=4)
               ->  Hash Join  (cost=1.05..12415.72 rows=41667 width=4)
                     Hash Cond: (a.bid = b.bid)
                     ->  Parallel Seq Scan on pgbench_accounts a  (cost=0.00..11623.00 rows=125000 width=8)
                     ->  Hash  (cost=1.04..1.04 rows=1 width=4)
                           ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4)
                                 Filter: (mname = 'Brittany'::bpchar)
(10 rows)
````


### Disable parallel processing 0 - max_parallel_workers_per_gather


```
max_connections;
 max_connections
-----------------
 100
(1 row)

Time: 0.527 ms
pgbench=# show max_parallel_workers_per_gather;
 max_parallel_workers_per_gather
---------------------------------
 2
(1 row)

Time: 19.057 ms
pgbench=# set max_parallel_workers_per_gather = 0;
SET
Time: 2.283 ms
```

### Hash Join plan without parallelization  

As per: https://dba.stackexchange.com/questions/226654/how-can-i-disable-parallel-queries-in-postgresql

```
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                               QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=15524.05..15524.06 rows=1 width=4) (actual time=391.480..391.480 rows=1 loops=1)
   Buffers: shared hit=10374
   ->  Hash Join  (cost=1.05..15274.05 rows=100000 width=4) (actual time=235.189..377.038 rows=100000 loops=1)
         Hash Cond: (a.bid = b.bid)
         Buffers: shared hit=10374
         ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.067..205.275 rows=300000 loops=1)
               Buffers: shared hit=10373
         ->  Hash  (cost=1.04..1.04 rows=1 width=4) (actual time=0.034..0.034 rows=1 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               Buffers: shared hit=1
               ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.015..0.017 rows=1 loops=1)
                     Filter: (mname = 'Brittany'::bpchar)
                     Rows Removed by Filter: 2
                     Buffers: shared hit=1
 Planning Time: 0.498 ms
 Execution Time: 393.393 ms
(16 rows)
```
### enable_hashjoin=false - plan switched to  Nested Loop
```
Time: 397.756 ms
pgbench=# set enable_hashjoin=false;
SET
Time: 0.281 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                              QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=17374.04..17374.05 rows=1 width=4) (actual time=113.200..113.200 rows=1 loops=1)
   Buffers: shared hit=10374
   ->  Nested Loop  (cost=0.00..17124.04 rows=100000 width=4) (actual time=38.879..102.074 rows=100000 loops=1)
         Join Filter: (a.bid = b.bid)
         Rows Removed by Join Filter: 200000
         Buffers: shared hit=10374
         ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.014..0.018 rows=1 loops=1)
               Filter: (mname = 'Brittany'::bpchar)
               Rows Removed by Filter: 2
               Buffers: shared hit=1
         ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.013..40.622 rows=300000 loops=1)
               Buffers: shared hit=10373
 Planning Time: 2.112 ms
 Execution Time: 113.275 ms
(14 rows)

Time: 116.042 ms
```
### enable_nestloop=false - plan switched to Merge Join

```
pgbench=# set enable_nestloop=false;
SET
Time: 0.960 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                                 QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47517.96..47517.97 rows=1 width=4) (actual time=237.029..237.029 rows=1 loops=1)
   Buffers: shared hit=10374, temp read=581 written=670
   ->  Merge Join  (cost=44767.95..47267.96 rows=100000 width=4) (actual time=190.973..227.355 rows=100000 loops=1)
         Merge Cond: (a.bid = b.bid)
         Buffers: shared hit=10374, temp read=581 written=670
         ->  Sort  (cost=44766.90..45516.90 rows=300000 width=8) (actual time=164.827..195.335 rows=200001 loops=1)
               Sort Key: a.bid
               Sort Method: external merge  Disk: 5320kB
               Buffers: shared hit=10373, temp read=581 written=670
               ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.037..62.477 rows=300000 loops=1)
                     Buffers: shared hit=10373
         ->  Sort  (cost=1.05..1.05 rows=1 width=4) (actual time=0.030..0.031 rows=1 loops=1)
               Sort Key: b.bid
               Sort Method: quicksort  Memory: 25kB
               Buffers: shared hit=1
               ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.017..0.017 rows=1 loops=1)
                     Filter: (mname = 'Brittany'::bpchar)
                     Rows Removed by Filter: 2
                     Buffers: shared hit=1
 Planning Time: 0.226 ms
 Execution Time: 244.781 ms
(21 rows)

Time: 246.893 ms
pgbench=# set enable_hashjoin=true;
SET
Time: 0.177 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                              QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=15524.05..15524.06 rows=1 width=4) (actual time=110.123..110.123 rows=1 loops=1)
   Buffers: shared hit=10374
   ->  Hash Join  (cost=1.05..15274.05 rows=100000 width=4) (actual time=41.520..100.212 rows=100000 loops=1)
         Hash Cond: (a.bid = b.bid)
         Buffers: shared hit=10374
         ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.020..36.417 rows=300000 loops=1)
               Buffers: shared hit=10373
         ->  Hash  (cost=1.04..1.04 rows=1 width=4) (actual time=0.008..0.008 rows=1 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               Buffers: shared hit=1
               ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.005..0.006 rows=1 loops=1)
                     Filter: (mname = 'Brittany'::bpchar)
                     Rows Removed by Filter: 2
                     Buffers: shared hit=1
 Planning Time: 0.112 ms
 Execution Time: 110.154 ms
(16 rows)

Time: 112.291 ms
```

### A few re-runs to guage the affect of buffering
```
pgbench=# set enable_hashjoin=false;
SET
Time: 0.172 ms
pgbench=# set enable_nestloop=true;
SET
Time: 0.337 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                              QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=17374.04..17374.05 rows=1 width=4) (actual time=213.381..213.381 rows=1 loops=1)
   Buffers: shared hit=10374
   ->  Nested Loop  (cost=0.00..17124.04 rows=100000 width=4) (actual time=85.587..186.251 rows=100000 loops=1)
         Join Filter: (a.bid = b.bid)
         Rows Removed by Join Filter: 200000
         Buffers: shared hit=10374
         ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.009..0.109 rows=1 loops=1)
               Filter: (mname = 'Brittany'::bpchar)
               Rows Removed by Filter: 2
               Buffers: shared hit=1
         ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.005..55.267 rows=300000 loops=1)
               Buffers: shared hit=10373
 Planning Time: 0.146 ms
 Execution Time: 213.410 ms
(14 rows)

Time: 214.283 ms
pgbench=# set enable_nestloop=false;
SET
Time: 0.262 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                                 QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47517.96..47517.97 rows=1 width=4) (actual time=282.548..282.548 rows=1 loops=1)
   Buffers: shared hit=10374, temp read=581 written=670
   ->  Merge Join  (cost=44767.95..47267.96 rows=100000 width=4) (actual time=235.949..272.089 rows=100000 loops=1)
         Merge Cond: (a.bid = b.bid)
         Buffers: shared hit=10374, temp read=581 written=670
         ->  Sort  (cost=44766.90..45516.90 rows=300000 width=8) (actual time=207.768..238.165 rows=200001 loops=1)
               Sort Key: a.bid
               Sort Method: external merge  Disk: 5320kB
               Buffers: shared hit=10373, temp read=581 written=670
               ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.021..74.763 rows=300000 loops=1)
                     Buffers: shared hit=10373
         ->  Sort  (cost=1.05..1.05 rows=1 width=4) (actual time=0.026..0.026 rows=1 loops=1)
               Sort Key: b.bid
               Sort Method: quicksort  Memory: 25kB
               Buffers: shared hit=1
               ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.016..0.017 rows=1 loops=1)
                     Filter: (mname = 'Brittany'::bpchar)
                     Rows Removed by Filter: 2
                     Buffers: shared hit=1
 Planning Time: 1.787 ms
 Execution Time: 288.097 ms
(21 rows)

Time: 291.986 ms
pgbench=# explain (analyze,buffers) select max(abalance) from pgbench_accounts a, pgbench_branches b where a.bid=b.bid and b.mname = 'Brittany';
                                                                 QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=47517.96..47517.97 rows=1 width=4) (actual time=209.107..209.107 rows=1 loops=1)
   Buffers: shared hit=10374, temp read=581 written=670
   ->  Merge Join  (cost=44767.95..47267.96 rows=100000 width=4) (actual time=163.143..199.096 rows=100000 loops=1)
         Merge Cond: (a.bid = b.bid)
         Buffers: shared hit=10374, temp read=581 written=670
         ->  Sort  (cost=44766.90..45516.90 rows=300000 width=8) (actual time=137.790..166.325 rows=200001 loops=1)
               Sort Key: a.bid
               Sort Method: external merge  Disk: 5320kB
               Buffers: shared hit=10373, temp read=581 written=670
               ->  Seq Scan on pgbench_accounts a  (cost=0.00..13373.00 rows=300000 width=8) (actual time=0.016..57.521 rows=300000 loops=1)
                     Buffers: shared hit=10373
         ->  Sort  (cost=1.05..1.05 rows=1 width=4) (actual time=0.022..0.022 rows=1 loops=1)
               Sort Key: b.bid
               Sort Method: quicksort  Memory: 25kB
               Buffers: shared hit=1
               ->  Seq Scan on pgbench_branches b  (cost=0.00..1.04 rows=1 width=4) (actual time=0.014..0.014 rows=1 loops=1)
                     Filter: (mname = 'Brittany'::bpchar)
                     Rows Removed by Filter: 2
                     Buffers: shared hit=1
 Planning Time: 0.205 ms
 Execution Time: 218.271 ms
(21 rows)

Time: 218.968 ms
pgbench=#
pgbench=# \d
```





