## Prepared statements, partitioning pruning and plan_cache_mode


### Summary

Prepared statements can massively improve performance (e.g.[pgbench-prepared-statements examples here](pgbench-prepared-statements.md), focus on the regular table example), however currently (pg13.7) this isn't working well with partitioning (e.g.[pgbench-prepared-statements-force_generic_plan examples here](pgbench-prepared-statements-force_generic_plan)) although there seems to be a workaround i.e. switch plan_cache_mode from auto to force_generic_plan.


I was curious about these pgbench based tests, which are great as far as they go but as below
* I wanted to break down the relative `Execution Time` and `Planning Time` within the query, not just look at the overall performance averages over 100K runs i.e. the focus of the above pgbench tests.
* As expected (given the pgbench tests linked above) `Execution Time` low (partition pruning working as expected) but relatively high `Planning Time` with plan_cache_mode=auto (i.e. of the order of x10 higher)
* Also I was curious if with plan_cache_mode=force_generic_plan and prepared statements, we still the partition pruning - which we still do, but planning down is down from around 0.5ms to 0.03ms, and given the exec times for this simple querry is around 0.1ms

NB The times above reflect averages and I've tried to factor out loading the buffer cache


### Details - plan_cache_mode=auto - `Execution Time` low (partition pruning working as expected) but relatively high `Planning Time`




```
[local] postgres@postgres=# show plan_cache_mode;
┌─────────────────┐
│ plan_cache_mode │
├─────────────────┤
│ auto            │
└─────────────────┘
(1 row)

Time: 1.066 ms
[local] postgres@postgres=# PREPARE pgbench_accounts_plan (int) as SELECT abalance FROM pgbench_accounts WHERE aid = $1;
PREPARE
Time: 0.800 ms
[local] postgres@postgres=# \timing
Timing is off.
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (600501);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                          QUERY PLAN                                                                           │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Index Scan using pgbench_accounts_10_pkey on pgbench_accounts_10 pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.029..0.030 rows=0 loops=1) │
│   Index Cond: (aid = 600501)                                                                                                                                  │
│   Buffers: shared hit=2                                                                                                                                       │
│ Planning:                                                                                                                                                     │
│   Buffers: shared hit=134                                                                                                                                     │
│ Planning Time: 1.180 ms                                                                                                                                       │
│ Execution Time: 0.060 ms                                                                                                                                      │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(7 rows)

[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (600001);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                          QUERY PLAN                                                                           │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Index Scan using pgbench_accounts_10_pkey on pgbench_accounts_10 pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.029..0.029 rows=0 loops=1) │
│   Index Cond: (aid = 600001)                                                                                                                                  │
│   Buffers: shared hit=2                                                                                                                                       │
│ Planning Time: 0.183 ms                                                                                                                                       │
│ Execution Time: 0.049 ms                                                                                                                                      │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(5 rows)

[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (167858);
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                         QUERY PLAN                                                                          │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Index Scan using pgbench_accounts_4_pkey on pgbench_accounts_4 pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.019..0.020 rows=1 loops=1) │
│   Index Cond: (aid = 167858)                                                                                                                                │
│   Buffers: shared hit=3                                                                                                                                     │
│ Planning:                                                                                                                                                   │
│   Buffers: shared hit=28                                                                                                                                    │
│ Planning Time: 0.323 ms                                                                                                                                     │
│ Execution Time: 0.034 ms                                                                                                                                    │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(7 rows)

[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (167857);
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                         QUERY PLAN                                                                          │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Index Scan using pgbench_accounts_4_pkey on pgbench_accounts_4 pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.015..0.017 rows=1 loops=1) │
│   Index Cond: (aid = 167857)                                                                                                                                │
│   Buffers: shared hit=3                                                                                                                                     │
│ Planning Time: 0.116 ms                                                                                                                                     │
│ Execution Time: 0.030 ms                                                                                                                                    │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(5 rows)

[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (600001);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                          QUERY PLAN                                                                           │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Index Scan using pgbench_accounts_10_pkey on pgbench_accounts_10 pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.034..0.035 rows=0 loops=1) │
│   Index Cond: (aid = 600001)                                                                                                                                  │
│   Buffers: shared hit=2                                                                                                                                       │
│ Planning Time: 0.306 ms                                                                                                                                       │
│ Execution Time: 0.076 ms                                                                                                                                      │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(5 rows)
```



###  Details - plan_cache_mode=force_generic_plan - `Execution Time` low (partition pruning still working as expected) and now low `Planning Time` too


```
[local] postgres@postgres=# show plan_cache_mode;
┌────────────────────┐
│  plan_cache_mode   │
├────────────────────┤
│ force_generic_plan │
└────────────────────┘
(1 row)

Time: 0.292 ms
[local] postgres@postgres=# explain EXECUTE pgbench_accounts_plan (300001);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                        QUERY PLAN                                                         │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4)                                                                                │
│   Subplans Removed: 9                                                                                                     │
│   ->  Index Scan using pgbench_accounts_7_pkey on pgbench_accounts_7 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) │
│         Index Cond: (aid = $1)                                                                                            │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(4 rows)

Time: 0.548 ms
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (300001);
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                             QUERY PLAN                                                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4) (actual time=5.237..5.243 rows=1 loops=1)                                                                                │
│   Buffers: shared read=3                                                                                                                                            │
│   Subplans Removed: 9                                                                                                                                               │
│   ->  Index Scan using pgbench_accounts_7_pkey on pgbench_accounts_7 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=5.236..5.239 rows=1 loops=1) │
│         Index Cond: (aid = $1)                                                                                                                                      │
│         Buffers: shared read=3                                                                                                                                      │
│ Planning Time: 0.023 ms                                                                                                                                             │
│ Execution Time: 5.291 ms                                                                                                                                            │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)

Time: 5.783 ms
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (300001);
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                             QUERY PLAN                                                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4) (actual time=0.018..0.020 rows=1 loops=1)                                                                                │
│   Buffers: shared hit=3                                                                                                                                             │
│   Subplans Removed: 9                                                                                                                                               │
│   ->  Index Scan using pgbench_accounts_7_pkey on pgbench_accounts_7 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=0.017..0.019 rows=1 loops=1) │
│         Index Cond: (aid = $1)                                                                                                                                      │
│         Buffers: shared hit=3                                                                                                                                       │
│ Planning Time: 0.042 ms                                                                                                                                             │
│ Execution Time: 0.078 ms                                                                                                                                            │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)

Time: 0.470 ms
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (167858);
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                             QUERY PLAN                                                                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4) (actual time=0.021..0.023 rows=1 loops=1)                                                                                │
│   Buffers: shared hit=3                                                                                                                                             │
│   Subplans Removed: 9                                                                                                                                               │
│   ->  Index Scan using pgbench_accounts_4_pkey on pgbench_accounts_4 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=0.020..0.022 rows=1 loops=1) │
│         Index Cond: (aid = $1)                                                                                                                                      │
│         Buffers: shared hit=3                                                                                                                                       │
│ Planning Time: 0.024 ms                                                                                                                                             │
│ Execution Time: 0.064 ms                                                                                                                                            │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)

Time: 0.528 ms
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (600001);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                              QUERY PLAN                                                                               │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4) (actual time=3.960..3.961 rows=0 loops=1)                                                                                  │
│   Buffers: shared read=2                                                                                                                                              │
│   Subplans Removed: 9                                                                                                                                                 │
│   ->  Index Scan using pgbench_accounts_10_pkey on pgbench_accounts_10 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=3.958..3.959 rows=0 loops=1) │
│         Index Cond: (aid = $1)                                                                                                                                        │
│         Buffers: shared read=2                                                                                                                                        │
│ Planning Time: 0.024 ms                                                                                                                                               │
│ Execution Time: 4.067 ms                                                                                                                                              │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)

Time: 4.513 ms
[local] postgres@postgres=# explain (analyze,buffers) EXECUTE pgbench_accounts_plan (600501);
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                              QUERY PLAN                                                                               │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Append  (cost=0.29..83.12 rows=10 width=4) (actual time=0.017..0.018 rows=0 loops=1)                                                                                  │
│   Buffers: shared hit=2                                                                                                                                               │
│   Subplans Removed: 9                                                                                                                                                 │
│   ->  Index Scan using pgbench_accounts_10_pkey on pgbench_accounts_10 pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=0.016..0.016 rows=0 loops=1) │
│         Index Cond: (aid = $1)                                                                                                                                        │
│         Buffers: shared hit=2                                                                                                                                         │
│ Planning Time: 0.023 ms                                                                                                                                               │
│ Execution Time: 0.059 ms                                                                                                                                              │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
(8 rows)
```