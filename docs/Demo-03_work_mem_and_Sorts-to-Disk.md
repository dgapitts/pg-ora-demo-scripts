## Demo-03 work_mem and Sorts-to-Disk


### Default work_mem only 4MB

```
bench1=# show work_mem;
 work_mem 
----------
 4MB
(1 row)
```

### In memory sorts `Sort Method: quicksort  Memory: ...`

* My pgench dataset is small and so we have an in-memory-sort 
* this is classed quicksort
* there is no external disk operations
* the `analyze` commands includes the size of sort i.e. 508kB (`Sort Method: quicksort  Memory: 508kB`


```
bench1=# explain (analyze,buffers) select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100000 and acc.aid < 10000 order by tid;
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=824.63..825.22 rows=237 width=144) (actual time=9.830..10.070 rows=1731 loops=1)
   Sort Key: hist.tid
   Sort Method: quicksort  Memory: 508kB
   Buffers: shared hit=301
   ->  Hash Join  (cost=320.05..815.28 rows=237 width=144) (actual time=3.711..8.767 rows=1731 loops=1)
         Hash Cond: (acc.aid = hist.aid)
         Buffers: shared hit=298
         ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..444.20 rows=9816 width=97) (actual time=0.013..2.811 rows=9999 loops=1)
               Index Cond: (aid < 10000)
               Buffers: shared hit=194
         ->  Hash  (cost=229.00..229.00 rows=7250 width=47) (actual time=3.649..3.650 rows=7251 loops=1)
               Buckets: 8192  Batches: 1  Memory Usage: 659kB
               Buffers: shared hit=104
               ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=7250 width=47) (actual time=0.014..1.998 rows=7251 loops=1)
                     Filter: (aid < 100000)
                     Rows Removed by Filter: 2749
                     Buffers: shared hit=104
 Planning Time: 1.826 ms
 Execution Time: 10.394 ms
(19 rows)
```

### Reduce work_mem to 500kB

```
bench1=# set work_mem='500kB';
SET
```

i.e. just below the 508kB threshold needed above to do this in memory



### Sort-to-disk `Sort Method: external merge  Disk: ....`

* My pgench dataset is small and so we have an in-memory-sort 
* this is classed external merge 
* the number of `Batches` is now 2 (it was one before) 
* the `analyze` commands includes the size of sort i.e. 280kB (`Sort Method: external merge  Disk: 280kB`)


```
bench1=# explain (analyze,buffers) select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100000 and acc.aid < 10000 order by tid;
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=1260.63..1261.22 rows=237 width=144) (actual time=13.777..14.141 rows=1731 loops=1)
   Sort Key: hist.tid
   Sort Method: external merge  Disk: 280kB
   Buffers: shared hit=298, temp read=138 written=138
   ->  Hash Join  (cost=384.05..1251.28 rows=237 width=144) (actual time=6.430..12.125 rows=1731 loops=1)
         Hash Cond: (acc.aid = hist.aid)
         Buffers: shared hit=298, temp read=103 written=103
         ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..444.20 rows=9816 width=97) (actual time=0.045..1.853 rows=9999 loops=1)
               Index Cond: (aid < 10000)
               Buffers: shared hit=194
         ->  Hash  (cost=229.00..229.00 rows=7250 width=47) (actual time=6.185..6.186 rows=7251 loops=1)
               Buckets: 8192  Batches: 2  Memory Usage: 366kB
               Buffers: shared hit=104, temp written=31
               ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=7250 width=47) (actual time=0.030..2.826 rows=7251 loops=1)
                     Filter: (aid < 100000)
                     Rows Removed by Filter: 2749
                     Buffers: shared hit=104
 Planning Time: 0.439 ms
 Execution Time: 14.452 ms
(19 rows)
```

