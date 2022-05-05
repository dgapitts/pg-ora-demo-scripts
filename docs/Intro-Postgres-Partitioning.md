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
