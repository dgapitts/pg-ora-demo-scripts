## Intro Postgres Partitioning


### Setup range partitions with pgbench (new pg13 feature)


As per [PostgreSQL 13 will come with partitioning support for pgbench](https://blog.dbi-services.com/postgresql-13-will-come-with-partitioning-support-for-pgbench/) this is a relatively new feature.


It is pretty easy to get going



```
-bash-4.2$ /usr/pgsql-13/bin/pgbench -i --partitions=3 --partition-method=range
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
creating 3 partitions...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.13 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.51 s (drop tables 0.01 s, create tables 0.05 s, client-side generate 0.18 s, vacuum 0.22 s, primary keys 0.05 s).
```

What has this created? 
* 3 range partitions for pgbench_accounts by PK (aid) 
* Approx 33.3K rows per patition 

```
postgres=# \d+ pgbench_accounts
                            Partitioned table "public.pgbench_accounts"
  Column  |     Type      | Collation | Nullable | Default | Storage  | Stats target | Description
----------+---------------+-----------+----------+---------+----------+--------------+-------------
 aid      | integer       |           | not null |         | plain    |              |
 bid      | integer       |           |          |         | plain    |              |
 abalance | integer       |           |          |         | plain    |              |
 filler   | character(84) |           |          |         | extended |              |
Partition key: RANGE (aid)
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)
Partitions: pgbench_accounts_1 FOR VALUES FROM (MINVALUE) TO (33335),
            pgbench_accounts_2 FOR VALUES FROM (33335) TO (66669),
            pgbench_accounts_3 FOR VALUES FROM (66669) TO (MAXVALUE)
```


### Example 01 - paritioning pruning - only needs pgbench_accounts_1 (Index Scan)

```
postgres=# explain select avg(abalance) from pgbench_accounts where aid < 10000;
                                                          QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=484.61..484.62 rows=1 width=32)
   ->  Index Scan using pgbench_accounts_1_pkey on pgbench_accounts_1 pgbench_accounts  (cost=0.29..459.57 rows=10016 width=4)
         Index Cond: (aid < 10000)
(3 rows)
```

### Example 02 - paritioning pruning - only needs pgbench_accounts_1 (Seq Scan)

```
postgres=# explain select avg(abalance) from pgbench_accounts where aid < 33000;
                                          QUERY PLAN
-----------------------------------------------------------------------------------------------
 Aggregate  (cost=1046.17..1046.18 rows=1 width=32)
   ->  Seq Scan on pgbench_accounts_1 pgbench_accounts  (cost=0.00..963.67 rows=32997 width=4)
         Filter: (aid < 33000)
(3 rows)
```

### Example 03 - paritioning pruning -  needs pgbench_accounts_1 (Seq Scan) and pgbench_accounts_2 (Index Scan)

```
postgres=# explain select avg(abalance) from pgbench_accounts where aid < 50000;
                                                     QUERY PLAN
--------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2100.40..2100.41 rows=1 width=32)
   ->  Append  (cost=0.00..1975.32 rows=50031 width=4)
         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..963.67 rows=33334 width=4)
               Filter: (aid < 50000)
         ->  Index Scan using pgbench_accounts_2_pkey on pgbench_accounts_2  (cost=0.29..761.49 rows=16697 width=4)
               Index Cond: (aid < 50000)
(6 rows)
```

### Example 04 - paritioning pruning -  needs pgbench_accounts_1 (Seq Scan) and pgbench_accounts_2 (Index Scan)

```
postgres=# explain select avg(abalance) from pgbench_accounts where aid < 34000;
                                                   QUERY PLAN
-----------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1254.02..1254.03 rows=1 width=32)
   ->  Append  (cost=0.00..1168.98 rows=34016 width=4)
         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..963.67 rows=33334 width=4)
               Filter: (aid < 34000)
         ->  Index Scan using pgbench_accounts_2_pkey on pgbench_accounts_2  (cost=0.29..35.23 rows=682 width=4)
               Index Cond: (aid < 34000)
(6 rows)
```


### Example 05 - paritioning pruning -  needs pgbench_accounts_1 (Seq Scan) and pgbench_accounts_2 (Seq Scan)

I've added `explain (analyze,buffers)` 
* 547 blocks per partition (33K rows)
* We have `Rows Removed by Filter: 1669` i.e.only 5% of 33K for `pgbench_accounts_2`

```
postgres=# explain (analyze,buffers) select avg(abalance) from pgbench_accounts where aid < 65000;
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2415.09..2415.10 rows=1 width=32) (actual time=18.693..18.695 rows=1 loops=1)
   Buffers: shared hit=1094
   ->  Append  (cost=0.00..2252.51 rows=65031 width=4) (actual time=0.012..14.335 rows=64999 loops=1)
         Buffers: shared hit=1094
         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..963.67 rows=33334 width=4) (actual time=0.012..5.563 rows=33334 loops=1)
               Filter: (aid < 65000)
               Buffers: shared hit=547
         ->  Seq Scan on pgbench_accounts_2  (cost=0.00..963.67 rows=31697 width=4) (actual time=0.027..3.987 rows=31665 loops=1)
               Filter: (aid < 65000)
               Rows Removed by Filter: 1669
               Buffers: shared hit=547
 Planning:
   Buffers: shared hit=3
 Planning Time: 0.150 ms
 Execution Time: 18.731 ms
(15 rows)
```

### Example 06 - no paritioning pruning -  needs pgbench_accounts_1 (Seq Scan), pgbench_accounts_2 (Seq Scan) and pgbench_accounts_3 (Index Scan)

Againg with `explain (analyze,buffers)` 
* 547 blocks per partition (33K rows) for pgbench_accounts_1 and pgbench_accounts_2
* 27 blocks read for `Index Scan using pgbench_accounts_3_pkey on pgbench_accounts_3` (returning 1333 rows out of 33K



```
postgres=# explain (analyze,buffers) select avg(abalance) from pgbench_accounts where aid < 68000;
                                                                          QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2501.98..2501.99 rows=1 width=32) (actual time=20.453..20.457 rows=1 loops=1)
   Buffers: shared hit=1094 read=27
   ->  Append  (cost=0.00..2331.97 rows=68001 width=4) (actual time=0.012..15.894 rows=67999 loops=1)
         Buffers: shared hit=1094 read=27
         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..963.67 rows=33334 width=4) (actual time=0.011..5.312 rows=33334 loops=1)
               Filter: (aid < 68000)
               Buffers: shared hit=547
         ->  Seq Scan on pgbench_accounts_2  (cost=0.00..963.67 rows=33334 width=4) (actual time=0.014..4.777 rows=33334 loops=1)
               Filter: (aid < 68000)
               Buffers: shared hit=547
         ->  Index Scan using pgbench_accounts_3_pkey on pgbench_accounts_3  (cost=0.29..64.62 rows=1333 width=4) (actual time=0.072..0.488 rows=1331 loops=1)
               Index Cond: (aid < 68000)
               Buffers: shared read=27
 Planning:
   Buffers: shared hit=25 read=3 dirtied=1
 Planning Time: 0.467 ms
 Execution Time: 20.553 ms
(17 rows)
```
