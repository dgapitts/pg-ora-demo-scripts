## Intro Postgres Partitioning - part two - hash paritioning 


### Setup hash partitions with pgbench (new pg13 feature)

As per [PostgreSQL 13 will come with partitioning support for pgbench](https://blog.dbi-services.com/postgresql-13-will-come-with-partitioning-support-for-pgbench/) this is a relatively new feature.

It is pretty easy to get going.

Im the [previous example](Intro-Postgres-Partitioning.md) we used `range` partion

```
/usr/pgsql-13/bin/pgbench -i --partitions=3 --partition-method=range
```

now lets compare to `hash` partitioning

```
-bash-4.2$ /usr/pgsql-13/bin/pgbench -i --partitions=3 --partition-method=hash
dropping old tables...
creating tables...
creating 3 partitions...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.11 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.30 s (drop tables 0.01 s, create tables 0.01 s, client-side generate 0.13 s, vacuum 0.11 s, primary keys 0.04 s).
```

What has this created? 
* 3 hash partitions for pgbench_accounts by mod(PK,3) 
* So again approx 33.3K rows per patition 

```
[local] postgres@postgres=# \d+ pgbench_accounts
                             Partitioned table "public.pgbench_accounts"
┌──────────┬───────────────┬───────────┬──────────┬─────────┬──────────┬──────────────┬─────────────┐
│  Column  │     Type      │ Collation │ Nullable │ Default │ Storage  │ Stats target │ Description │
├──────────┼───────────────┼───────────┼──────────┼─────────┼──────────┼──────────────┼─────────────┤
│ aid      │ integer       │           │ not null │         │ plain    │              │             │
│ bid      │ integer       │           │          │         │ plain    │              │             │
│ abalance │ integer       │           │          │         │ plain    │              │             │
│ filler   │ character(84) │           │          │         │ extended │              │             │
└──────────┴───────────────┴───────────┴──────────┴─────────┴──────────┴──────────────┴─────────────┘
Partition key: HASH (aid)
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)
Partitions: pgbench_accounts_1 FOR VALUES WITH (modulus 3, remainder 0),
            pgbench_accounts_2 FOR VALUES WITH (modulus 3, remainder 1),
            pgbench_accounts_3 FOR VALUES WITH (modulus 3, remainder 2)
```


### Example 01 - potential to parallelize but no paritioning pruning 

This has the potential to parallelize but no paritioning pruning

```
[local] postgres@postgres=# explain select avg(abalance) from pgbench_accounts where aid < 10000;
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                    QUERY PLAN                                                     │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Aggregate  (cost=546.60..546.61 rows=1 width=32)                                                                  │
│   ->  Append  (cost=0.29..521.52 rows=10029 width=4)                                                              │
│         ->  Index Scan using pgbench_accounts_1_pkey on pgbench_accounts_1  (cost=0.29..154.79 rows=3286 width=4) │
│               Index Cond: (aid < 10000)                                                                           │
│         ->  Index Scan using pgbench_accounts_2_pkey on pgbench_accounts_2  (cost=0.29..158.34 rows=3374 width=4) │
│               Index Cond: (aid < 10000)                                                                           │
│         ->  Index Scan using pgbench_accounts_3_pkey on pgbench_accounts_3  (cost=0.29..158.25 rows=3369 width=4) │
│               Index Cond: (aid < 10000)                                                                           │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)
```

### Example 02 - analyze,buffers - again potential to parallelize but no paritioning pruning

```
[local] postgres@postgres=#  explain (analyze,buffers) select avg(abalance) from pgbench_accounts where aid < 100000;
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                            QUERY PLAN                                                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Aggregate  (cost=3640.99..3641.01 rows=1 width=32) (actual time=29.236..29.237 rows=1 loops=1)                                   │
│   Buffers: shared hit=1641                                                                                                       │
│   ->  Append  (cost=0.00..3390.99 rows=99999 width=4) (actual time=0.009..23.006 rows=99999 loops=1)                             │
│         Buffers: shared hit=1641                                                                                                 │
│         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..970.81 rows=33584 width=4) (actual time=0.009..5.173 rows=33584 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Rows Removed by Filter: 1                                                                                          │
│               Buffers: shared hit=551                                                                                            │
│         ->  Seq Scan on pgbench_accounts_2  (cost=0.00..968.67 rows=33494 width=4) (actual time=0.007..5.479 rows=33494 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Buffers: shared hit=550                                                                                            │
│         ->  Seq Scan on pgbench_accounts_3  (cost=0.00..951.51 rows=32921 width=4) (actual time=0.010..4.834 rows=32921 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Buffers: shared hit=540                                                                                            │
│ Planning:                                                                                                                        │
│   Buffers: shared hit=3 read=6                                                                                                   │
│ Planning Time: 0.258 ms                                                                                                          │
│ Execution Time: 29.269 ms                                                                                                        │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(18 rows)
```

and now selecting early every row:
```
Time: 29.839 ms
[local] postgres@postgres=#  explain (analyze,buffers) select avg(abalance) from pgbench_accounts where aid < 100000;
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                            QUERY PLAN                                                            │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Aggregate  (cost=3640.99..3641.01 rows=1 width=32) (actual time=29.339..29.341 rows=1 loops=1)                                   │
│   Buffers: shared hit=1641                                                                                                       │
│   ->  Append  (cost=0.00..3390.99 rows=99999 width=4) (actual time=0.009..23.138 rows=99999 loops=1)                             │
│         Buffers: shared hit=1641                                                                                                 │
│         ->  Seq Scan on pgbench_accounts_1  (cost=0.00..970.81 rows=33584 width=4) (actual time=0.009..5.198 rows=33584 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Rows Removed by Filter: 1                                                                                          │
│               Buffers: shared hit=551                                                                                            │
│         ->  Seq Scan on pgbench_accounts_2  (cost=0.00..968.67 rows=33494 width=4) (actual time=0.007..5.500 rows=33494 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Buffers: shared hit=550                                                                                            │
│         ->  Seq Scan on pgbench_accounts_3  (cost=0.00..951.51 rows=32921 width=4) (actual time=0.012..5.393 rows=32921 loops=1) │
│               Filter: (aid < 100000)                                                                                             │
│               Buffers: shared hit=540                                                                                            │
│ Planning:                                                                                                                        │
│   Buffers: shared hit=9                                                                                                          │
│ Planning Time: 0.177 ms                                                                                                          │
│ Execution Time: 29.373 ms                                                                                                        │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(18 rows)

Time: 29.862 ms
```
