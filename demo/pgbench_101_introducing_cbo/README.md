### Introducing the Cost Based Optimizer - scan the table vs use the index


Assuming you've done the setup pgbench databases
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


now the following query takes about 45ms and has an optimizer cost of 7919

```
-bash-4.2$ psql -d pgbench
psql (9.6.17)
Type "help" for help.

pgbench=# explain (analyze,buffers,verbose) select * from pgbench_accounts;
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=97) (actual time=0.161..32.774 rows=300000 loops=1)
   Output: aid, bid, abalance, filler
   Buffers: shared hit=2208 read=2711
 Planning time: 0.985 ms
 Execution time: 45.377 ms
(5 rows)
```

### Background seq_page_cost vs random_page_cost 

```
seq_page_cost (floating point)
Sets the planner's estimate of the cost of a disk page fetch that is part of a series of sequential fetches. The default is 1.0. This value can be overridden for tables and indexes in a particular tablespace by setting the tablespace parameter of the same name (see ALTER TABLESPACE).

random_page_cost (floating point)
Sets the planner's estimate of the cost of a non-sequentially-fetched disk page. The default is 4.0. This value can be overridden for tables and indexes in a particular tablespace by setting the tablespace parameter of the same name (see ALTER TABLESPACE).
```

https://www.postgresql.org/docs/12/runtime-config-query.html


### Adjusting seq_page_cost

```
pgbench=# show seq_page_cost;
 seq_page_cost
---------------
 1
(1 row)

pgbench=# set seq_page_cost=2;
SET
pgbench=# explain (analyze,buffers,verbose) select * from pgbench_accounts;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.pgbench_accounts  (cost=0.00..12838.00 rows=300000 width=97) (actual time=0.038..32.264 rows=300000 loops=1)
   Output: aid, bid, abalance, filler
   Buffers: shared hit=2240 read=2679
 Planning time: 0.038 ms
 Execution time: 46.821 ms
(5 rows)

pgbench=# set seq_page_cost=3;
SET
pgbench=# explain (analyze,buffers,verbose) select * from pgbench_accounts;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.pgbench_accounts  (cost=0.00..17757.00 rows=300000 width=97) (actual time=0.048..29.997 rows=300000 loops=1)
   Output: aid, bid, abalance, filler
   Buffers: shared hit=2272 read=2647
 Planning time: 0.039 ms
 Execution time: 42.413 ms
(5 rows)
```

### Adjusting seq_page_cost and the point where we switch from a Index Scan to Seq Scan 

```
pgbench=# \d pgbench_accounts
   Table "public.pgbench_accounts"
  Column  |     Type      | Modifiers
----------+---------------+-----------
 aid      | integer       | not null
 bid      | integer       |
 abalance | integer       |
 filler   | character(84) |
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)

pgbench=# explain  select * from pgbench_accounts where aid < 100;
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..13.29 rows=107 width=97)
   Index Cond: (aid < 100)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 1000;
                                            QUERY PLAN
---------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..86.38 rows=1083 width=97)
   Index Cond: (aid < 1000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 10000;
                                             QUERY PLAN
-----------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..808.34 rows=10338 width=97)
   Index Cond: (aid < 10000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 100000;
                                              QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7710.11 rows=99182 width=97)
   Index Cond: (aid < 100000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 1000000;
                                QUERY PLAN
--------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..18507.00 rows=300000 width=97)
   Filter: (aid < 1000000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 500000;
                                QUERY PLAN
--------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..18507.00 rows=300000 width=97)
   Filter: (aid < 500000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 250000;
                                QUERY PLAN
--------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..18507.00 rows=249372 width=97)
   Filter: (aid < 250000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 150000;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11630.39 rows=149655 width=97)
   Index Cond: (aid < 150000)
(2 rows)

pgbench=# set seq_page_cost=1;
SET
pgbench=# explain  select * from pgbench_accounts where aid < 150000;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..6724.39 rows=149655 width=97)
   Index Cond: (aid < 150000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 100000;
                                              QUERY PLAN
------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..4458.11 rows=99182 width=97)
   Index Cond: (aid < 100000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 150000;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..6724.39 rows=149655 width=97)
   Index Cond: (aid < 150000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 200000;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=200113 width=97)
   Filter: (aid < 200000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 175000;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7839.19 rows=174501 width=97)
   Index Cond: (aid < 175000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 188000;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8454.89 rows=188198 width=97)
   Index Cond: (aid < 188000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 194000;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=194363 width=97)
   Filter: (aid < 194000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 191000;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191347 width=97)
   Filter: (aid < 191000)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 189500;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8526.08 rows=189809 width=97)
   Index Cond: (aid < 189500)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 169300;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7578.55 rows=168693 width=97)
   Index Cond: (aid < 169300)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190300;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8565.43 rows=190629 width=97)
   Index Cond: (aid < 190300)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190700;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191039 width=97)
   Filter: (aid < 190700)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190500;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8573.02 rows=190834 width=97)
   Index Cond: (aid < 190500)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190600;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8579.82 rows=190937 width=97)
   Index Cond: (aid < 190600)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190650;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8581.71 rows=190988 width=97)
   Index Cond: (aid < 190650)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190680;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191019 width=97)
   Filter: (aid < 190680)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190670;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8582.08 rows=191009 width=97)
   Index Cond: (aid < 190670)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190675;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8582.17 rows=191014 width=97)
   Index Cond: (aid < 190675)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190679;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191018 width=97)
   Filter: (aid < 190679)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190678;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191017 width=97)
   Filter: (aid < 190678)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190677;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191016 width=97)
   Filter: (aid < 190677)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190676;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191015 width=97)
   Filter: (aid < 190676)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190675;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..8582.17 rows=191014 width=97)
   Index Cond: (aid < 190675)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190676;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=191015 width=97)
   Filter: (aid < 190676)
(2 rows)
```
### As above seq_page_cost=1 the cut-off point for a Seq (table) was aid < 190676; 
```
pgbench=# set seq_page_cost=2;
SET
pgbench=# explain  select * from pgbench_accounts where aid < 190676;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11715.18 rows=191015 width=97)
   Index Cond: (aid < 190676)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190677;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11715.20 rows=191016 width=97)
   Index Cond: (aid < 190677)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 190678;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11715.22 rows=191017 width=97)
   Index Cond: (aid < 190678)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 191678;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11777.14 rows=192041 width=97)
   Index Cond: (aid < 191678)
(2 rows)

pgbench=# explain  select * from pgbench_accounts where aid < 192678;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..11836.64 rows=193041 width=97)
   Index Cond: (aid < 192678)
(2 rows)

pgbench=# set seq_page_cost=1;
SET
pgbench=# explain  select * from pgbench_accounts where aid < 192678;
                               QUERY PLAN
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..8669.00 rows=193041 width=97)
   Filter: (aid < 192678)
(2 rows)
```