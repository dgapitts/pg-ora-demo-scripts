
# Demo-06 Postgres optimizer NOT IN gotcha - still in pg12

## Summary

Be very carefully around NOT IN clause in postgres, as per the example below the NOT EXISTS equivalent statement works dramatically better as it doesn't have to `Materialize`.

## Background this is an old issue in pg96 and the community are trying to work on these 
I've docuented this broader ["postgres edge" befor ](../loadtest/postgres-gotcha01-not-in/README.md), in the context of pg96.

I've also mentioned this at postgres usergroups and their was acknowledgement that there are soe edge 

Continuing on from Demo-04 and Demo-05 where I have already documented some of the problem plans, 

```
 select count(bid) from pgbench_branches branch 
 where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);

 select count(bid) from pgbench_branches 
 where bid NOT IN (select bid from pgbench_accounts);
```

The above two queries are broadly logically equivalent (although I still need to check that they handle NULL values in the same manner).

Lets add the obvious index to help accouts table searches over bid (branch id)

```
bench1=# create index pgbench_accounts_bid on pgbench_accounts(bid);
CREATE 
```

## NOT EXISTS takes 0.22ms and is only 7 logical reads
```
bench1=# explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
   
                                                                               QUERY PLAN                                                                               
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2.51..2.52 rows=1 width=8) (actual time=0.173..0.174 rows=1 loops=1)
   Buffers: shared hit=4 read=7
   ->  Nested Loop Anti Join  (cost=0.42..2.51 rows=1 width=4) (actual time=0.170..0.171 rows=0 loops=1)
         Buffers: shared hit=4 read=7
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.03 rows=3 width=4) (actual time=0.007..0.009 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.42..2486.42 rows=100000 width=4) (actual time=0.052..0.052 rows=1 loops=3)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=3 read=7
 Planning Time: 0.338 ms
 Execution Time: 0.224 ms
(12 rows)
```



## NOT IN takes 112.35ms and is only 544 logical reads plus an expensive "sort to disc" operation
```
bench1=# explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=16846.47..16846.47 rows=1 width=8) (actual time=111.549..111.550 rows=1 loops=1)
   Buffers: shared hit=7 read=544, temp read=171 written=341
   ->  Seq Scan on pgbench_branches  (cost=0.42..16846.46 rows=2 width=4) (actual time=111.543..111.544 rows=0 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 3
         Buffers: shared hit=7 read=544, temp read=171 written=341
         SubPlan 1
           ->  Materialize  (cost=0.42..10480.42 rows=300000 width=4) (actual time=0.017..28.832 rows=100001 loops=3)
                 Buffers: shared hit=6 read=544, temp read=171 written=341
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.42..7808.42 rows=300000 width=4) (actual time=0.034..27.857 rows=200001 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=6 read=544
 Planning Time: 0.432 ms
 Execution Time: 112.350 ms
(14 rows)

```


## pg12 version details

```
bench1=# select version();
                                                 version                                                 
---------------------------------------------------------------------------------------------------------
 PostgreSQL 12.5 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-39), 64-bit
(1 row)
```
