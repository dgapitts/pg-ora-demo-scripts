# Summary

This is a class postgres gotcha which I have demo via a very simple pgbench dataset.

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

# Details - bad plan - NOT IN

```
select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

                                                                 QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7920.57..7920.58 rows=1 width=8) (actual time=208.799..208.799 rows=1 loops=1)
   Buffers: shared hit=4698 read=10061
   ->  Nested Loop Anti Join  (cost=0.00..7920.57 rows=1 width=4) (actual time=148.023..208.791 rows=2 loops=1)
         Join Filter: (account.bid = branch.bid)
\timing on
         Rows Removed by Join Filter: 900000
         Buffers: shared hit=4698 read=10061
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.03 rows=3 width=4) (actual time=0.005..0.007 rows=5 loops=1)
               Buffers: shared hit=1
         ->  Seq Scan on pgbench_accounts account  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.011..23.121 rows=180001 loops=5)
               Buffers: shared hit=4697 read=10061
 Planning time: 0.378 ms
 Execution time: 208.889 ms
(12 rows)
```

# Details - good plan - NOT EXISTS

```
select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);

                                                                 QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=17012.54..17012.55 rows=1 width=8) (actual time=215.329..215.329 rows=1 loops=1)
   Buffers: shared hit=2145 read=2775, temp read=1029 written=513
   ->  Seq Scan on pgbench_branches  (cost=0.00..17012.54 rows=2 width=4) (actual time=165.256..215.315 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 3
         Buffers: shared hit=2145 read=2775, temp read=1029 written=513
         SubPlan 1
           ->  Materialize  (cost=0.00..10591.00 rows=300000 width=4) (actual time=0.019..28.571 rows=180001 loops=5)
                 Buffers: shared hit=2144 read=2775, temp read=1029 written=513
                 ->  Seq Scan on pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.024..45.678 rows=300000 loops=1)
                       Buffers: shared hit=2144 read=2775
 Planning time: 0.089 ms
 Execution time: 216.341 ms
 ```
