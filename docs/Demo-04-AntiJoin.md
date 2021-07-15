## Anti Join (with nested loops)

Using a NOT EXISTS statement 
```
bench1=# explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7920.57..7920.58 rows=1 width=8) (actual time=65.700..65.701 rows=1 loops=1)
   Buffers: shared hit=1472 read=3449
   ->  Nested Loop Anti Join  (cost=0.00..7920.57 rows=1 width=4) (actual time=65.694..65.695 rows=0 loops=1)
         Join Filter: (account.bid = branch.bid)
         Rows Removed by Join Filter: 300000
         Buffers: shared hit=1472 read=3449
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.03 rows=3 width=4) (actual time=0.016..0.019 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Seq Scan on pgbench_accounts account  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.005..12.645 rows=100001 loops=3)
               Buffers: shared hit=1471 read=3449
 Planning Time: 0.565 ms
 Execution Time: 65.756 ms
(12 rows)
```

to understand the above metrics
* there are 3 branchs (actual time=0.016..0.019 rows=3 loops=1)
* for each each branch there are 10K rows to check (actual time=0.005..12.645 rows=100001 loops=3)
* all of these match, so in the context of an ANTI JOIN we have 3x10K discards (Rows Removed by Join Filter: 300000)

To further points to note
* the 10K pgbench_accounts datasets is getting quite large - at some stage this is likely to seitch to a Hash Anti Join
* we can also validate the above metrics via simple adhoc queries:

```
bench1=# select bid, count(*) from pgbench_branches group by bid;
 bid | count 
-----+-------
   1 |     1
   2 |     1
   3 |     1
(3 rows)

bench1=# select bid, count(*) from pgbench_accounts group by bid;
 bid | count  
-----+--------
   1 | 100000
   2 | 100000
   3 | 100000
(3 rows)

bench1=# select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
 count 
-------
     0
(1 row)
```