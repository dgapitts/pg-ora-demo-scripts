# Exploring-Yugabytedb

Notes for paris-notes (WIP)

Can't argue with this:

> LSM engines are the de facto standard today for handling workloads with large fast-growing data.
https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-the-basics/


and after reading the docos, running some simple (single nodes)

* LSM - RocksDB storage 
* MVCC - Read-Commited
* ANALYZE appears to be a beta-feature!?
```
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 5743.785 ms (00:05.744)
```
* Some strange costs i.e. expecting `17103` rows but there were only `4`
```
bench1=# explain (analyze,buffers) select filler from big_table where id = 80000;
explain (analyze,buffers) select filler from big_table where id = 80000;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..2099.12 rows=17103 width=218) (actual time=8.996..9.050 rows=4 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 7.983 ms
 Execution Time: 10.065 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 94.302 ms
```
* Nice GUI interface
![Yugabytedb-GUI-interface](Yugabytedb-GUI-interface.png)


