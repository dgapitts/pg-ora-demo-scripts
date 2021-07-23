## Demo-05 Materialize SubPlan

I've docuented this broader ["postgres edge" before](../loadtest/postgres-gotcha01-not-in/README.md), but here I want to focus on the Materialize SubPlan

```
bench1=# explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
                                                                 QUERY PLAN                                                                 
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=17012.54..17012.55 rows=1 width=8) (actual time=120.001..120.002 rows=1 loops=1)
   Buffers: shared hit=1340 read=1940, temp read=171 written=341
   ->  Seq Scan on pgbench_branches  (cost=0.00..17012.54 rows=2 width=4) (actual time=119.994..119.995 rows=0 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 3
         Buffers: shared hit=1340 read=1940, temp read=171 written=341
         SubPlan 1
           ->  Materialize  (cost=0.00..10591.00 rows=300000 width=4) (actual time=0.013..31.884 rows=100001 loops=3)
                 Buffers: shared hit=1339 read=1940, temp read=171 written=341
                 ->  Seq Scan on pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.017..35.289 rows=200001 loops=1)
                       Buffers: shared hit=1339 read=1940
 Planning Time: 2.098 ms
 Execution Time: 121.659 ms
(13 rows)
```


even with this relatively small dataset notice also involves extra disc IO `temp read=171 written=341` i.e. with the default work_mem setting

```
bench1=# show work_mem;
 work_mem 
----------
 4MB
(1 row)

```




