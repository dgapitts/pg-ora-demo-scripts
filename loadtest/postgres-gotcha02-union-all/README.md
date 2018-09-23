# Summary

This postgres gotcha is actually also an issue in Oracle and technically is bad/inefficient SQL by the developer, an inefficient existence check over two or more tables.

However I think the Oracle optimizer handles this inefficient existence check better? To be confirmed 

# Setup with pgbench (scale factor 3)

```
-bash-4.2$ grep bench1 ~/.pgpass
localhost:5432:*:bench1:***
-bash-4.2$ pgbench -i -s 3 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 300000 tuples (33%) done (elapsed 0.04 s, remaining 0.08 s)
200000 of 300000 tuples (66%) done (elapsed 0.09 s, remaining 0.05 s)
300000 of 300000 tuples (100%) done (elapsed 0.16 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
```

# Details - bad plan - regular UNION (no deduplicate)

```
bench1=> explain (analyze, buffers) (select 1 from pgbench_branches UNION  select 1 from pgbench_accounts) limit 1;
                                                                                    QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=42195.68..42195.69 rows=1 width=4) (actual time=130.374..130.377 rows=1 loops=1)
   Buffers: shared hit=824, temp read=1 written=513
   ->  Unique  (cost=42195.68..43695.70 rows=300003 width=4) (actual time=130.372..130.372 rows=1 loops=1)
         Buffers: shared hit=824, temp read=1 written=513
         ->  Sort  (cost=42195.68..42945.69 rows=300003 width=4) (actual time=130.372..130.372 rows=1 loops=1)
               Sort Key: (1)
               Sort Method: external sort  Disk: 4104kB
               Buffers: shared hit=824, temp read=1 written=513
               ->  Append  (cost=0.00..10801.48 rows=300003 width=4) (actual time=0.009..63.817 rows=300003 loops=1)
                     Buffers: shared hit=824
                     ->  Seq Scan on pgbench_branches  (cost=0.00..1.03 rows=3 width=4) (actual time=0.009..0.009 rows=3 loops=1)
                           Buffers: shared hit=1
                     ->  Index Only Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7800.42 rows=300000 width=4) (actual time=0.084..38.963 rows=300000 loops=1)
                           Heap Fetches: 0
                           Buffers: shared hit=823
 Planning time: 0.089 ms
 Execution time: 131.226 ms
(17 rows)
```

# Details - good plan - UNION ALL (no sort operation and deduplication of data)

```
bench1=> explain (analyze, buffers) (select 1 from pgbench_branches UNION ALL select 1 from pgbench_accounts) limit 1;
                                                               QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..0.03 rows=1 width=4) (actual time=0.009..0.010 rows=1 loops=1)
   Buffers: shared hit=1
   ->  Append  (cost=0.00..7801.45 rows=300003 width=4) (actual time=0.008..0.008 rows=1 loops=1)
         Buffers: shared hit=1
         ->  Seq Scan on pgbench_branches  (cost=0.00..1.03 rows=3 width=4) (actual time=0.007..0.007 rows=1 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7800.42 rows=300000 width=4) (never executed)
               Heap Fetches: 0
 Planning time: 0.087 ms
 Execution time: 0.027 ms
(10 rows)

 ```
