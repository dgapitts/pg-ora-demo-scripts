# Demo-09 More Columnar Projected Columns

## Background 
After a bit of intro:

* [Install citus RPMs and pg extension](install-citus-RPMs-and-pg-extension.md)
* [Introduction to Columnar Compression](intro-columnar-compression.md)t

I can extend this basic intro

* [Demo-08 Introducing Columnar Projected Columns](Demo08-Columnar-Projected-Columns.md)

## Setup 500K row tables perf_row and perf_columnar

```
[pg12centos7:postgres:/tmp] # cat 002_microbenchmark_reduceio.sql
-- https://www.citusdata.com/blog/2021/03/06/citus-10-columnar-compression-for-postgres/


CREATE TABLE perf_row(
  c00 int8, c01 int8, c02 int8, c03 int8, c04 int8, c05 int8, c06 int8, c07 int8, c08 int8, c09 int8,
  c10 int8, c11 int8, c12 int8, c13 int8, c14 int8, c15 int8, c16 int8, c17 int8, c18 int8, c19 int8,
  c20 int8, c21 int8, c22 int8, c23 int8, c24 int8, c25 int8, c26 int8, c27 int8, c28 int8, c29 int8,
  c30 int8, c31 int8, c32 int8, c33 int8, c34 int8, c35 int8, c36 int8, c37 int8, c38 int8, c39 int8,
  c40 int8, c41 int8, c42 int8, c43 int8, c44 int8, c45 int8, c46 int8, c47 int8, c48 int8, c49 int8,
  c50 int8, c51 int8, c52 int8, c53 int8, c54 int8, c55 int8, c56 int8, c57 int8, c58 int8, c59 int8,
  c60 int8, c61 int8, c62 int8, c63 int8, c64 int8, c65 int8, c66 int8, c67 int8, c68 int8, c69 int8,
  c70 int8, c71 int8, c72 int8, c73 int8, c74 int8, c75 int8, c76 int8, c77 int8, c78 int8, c79 int8,
  c80 int8, c81 int8, c82 int8, c83 int8, c84 int8, c85 int8, c86 int8, c87 int8, c88 int8, c89 int8,
  c90 int8, c91 int8, c92 int8, c93 int8, c94 int8, c95 int8, c96 int8, c97 int8, c98 int8, c99 int8
);

CREATE TABLE perf_columnar(LIKE perf_row) USING COLUMNAR;

\timing on

INSERT INTO perf_row
  SELECT
    g % 00500, g % 01000, g % 01500, g % 02000, g % 02500, g % 03000, g % 03500, g % 04000, g % 04500, g % 05000,
    g % 05500, g % 06000, g % 06500, g % 07000, g % 07500, g % 08000, g % 08500, g % 09000, g % 09500, g % 10000,
    g % 10500, g % 11000, g % 11500, g % 12000, g % 12500, g % 13000, g % 13500, g % 14000, g % 14500, g % 15000,
    g % 15500, g % 16000, g % 16500, g % 17000, g % 17500, g % 18000, g % 18500, g % 19000, g % 19500, g % 20000,
    g % 20500, g % 21000, g % 21500, g % 22000, g % 22500, g % 23000, g % 23500, g % 24000, g % 24500, g % 25000,
    g % 25500, g % 26000, g % 26500, g % 27000, g % 27500, g % 28000, g % 28500, g % 29000, g % 29500, g % 30000,
    g % 30500, g % 31000, g % 31500, g % 32000, g % 32500, g % 33000, g % 33500, g % 34000, g % 34500, g % 35000,
    g % 35500, g % 36000, g % 36500, g % 37000, g % 37500, g % 38000, g % 38500, g % 39000, g % 39500, g % 40000,
    g % 40500, g % 41000, g % 41500, g % 42000, g % 42500, g % 43000, g % 43500, g % 44000, g % 44500, g % 45000,
    g % 45500, g % 46000, g % 46500, g % 47000, g % 47500, g % 48000, g % 48500, g % 49000, g % 49500, g % 50000
  FROM generate_series(1,500000) g;

INSERT INTO perf_columnar
  SELECT
    g % 00500, g % 01000, g % 01500, g % 02000, g % 02500, g % 03000, g % 03500, g % 04000, g % 04500, g % 05000,
    g % 05500, g % 06000, g % 06500, g % 07000, g % 07500, g % 08000, g % 08500, g % 09000, g % 09500, g % 10000,
    g % 10500, g % 11000, g % 11500, g % 12000, g % 12500, g % 13000, g % 13500, g % 14000, g % 14500, g % 15000,
    g % 15500, g % 16000, g % 16500, g % 17000, g % 17500, g % 18000, g % 18500, g % 19000, g % 19500, g % 20000,
    g % 20500, g % 21000, g % 21500, g % 22000, g % 22500, g % 23000, g % 23500, g % 24000, g % 24500, g % 25000,
    g % 25500, g % 26000, g % 26500, g % 27000, g % 27500, g % 28000, g % 28500, g % 29000, g % 29500, g % 30000,
    g % 30500, g % 31000, g % 31500, g % 32000, g % 32500, g % 33000, g % 33500, g % 34000, g % 34500, g % 35000,
    g % 35500, g % 36000, g % 36500, g % 37000, g % 37500, g % 38000, g % 38500, g % 39000, g % 39500, g % 40000,
    g % 40500, g % 41000, g % 41500, g % 42000, g % 42500, g % 43000, g % 43500, g % 44000, g % 44500, g % 45000,
    g % 45500, g % 46000, g % 46500, g % 47000, g % 47500, g % 48000, g % 48500, g % 49000, g % 49500, g % 50000
  FROM generate_series(1,500000) g;

VACUUM VERBOSE perf_row;
VACUUM VERBOSE perf_columnar;

-- checkpoint if superuser; otherwise wait for system to settle
CHECKPOINT; CHECKPOINT;


SELECT pg_size_pretty(pg_total_relation_size('perf_row')), pg_size_pretty(pg_total_relation_size('perf_columnar')), 
       round(pg_total_relation_size('perf_row')::numeric/pg_total_relation_size('perf_columnar'),1) AS compression_ratio;
```


```
[pg12centos7:postgres:/tmp] # psql 
psql (12.5)
Type "help" for help.

postgres=# SELECT pg_size_pretty(pg_total_relation_size('perf_row')), pg_size_pretty(pg_total_relation_size('perf_columnar')), 
postgres-#        round(pg_total_relation_size('perf_row')::numeric/pg_total_relation_size('perf_columnar'),1) AS compression_ratio;
 pg_size_pretty | pg_size_pretty | compression_ratio 
----------------+----------------+-------------------
 434 MB         | 65 MB          |               6.7
(1 row)
```

```
postgres=# SET max_parallel_workers_per_gather = 0;
SET
postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_row GROUP BY c00;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64305.95..64313.45 rows=500 width=72) (actual time=2688.463..2688.767 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=7565 read=47991
   ->  Seq Scan on perf_row  (cost=0.00..60555.97 rows=499997 width=24) (actual time=2.219..1810.837 rows=500000 loops=1)
         Buffers: shared hit=7565 read=47991
 Planning Time: 9.380 ms
 Execution Time: 2689.420 ms
(7 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_row GROUP BY c00;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64305.95..64313.45 rows=500 width=72) (actual time=1333.790..1334.086 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=7573 read=47983
   ->  Seq Scan on perf_row  (cost=0.00..60555.97 rows=499997 width=24) (actual time=10.272..766.986 rows=500000 loops=1)
         Buffers: shared hit=7573 read=47983
 Planning Time: 0.103 ms
 Execution Time: 1334.195 ms
(7 rows)
```

and running again (now data is largely in shared_buffers)
```
postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_columnar GROUP BY c00;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=3997.69..4000.69 rows=200 width=72) (actual time=227.176..227.861 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=686 read=1
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..247.69 rows=500000 width=24) (actual time=17.383..121.496 rows=500000 loops=1)
         Columnar Projected Columns: c00, c29, c71
         Buffers: shared hit=686 read=1
 Planning Time: 11.825 ms
 Execution Time: 228.159 ms
(8 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_columnar GROUP BY c00;
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=3997.69..4000.69 rows=200 width=72) (actual time=217.555..217.847 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=640
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..247.69 rows=500000 width=24) (actual time=3.459..109.362 rows=500000 loops=1)
         Columnar Projected Columns: c00, c29, c71
         Buffers: shared hit=640
 Planning Time: 0.232 ms
 Execution Time: 217.931 ms
(8 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_row GROUP BY c00;
                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64305.95..64313.45 rows=500 width=72) (actual time=2531.352..2531.641 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=7605 read=47951
   ->  Seq Scan on perf_row  (cost=0.00..60555.97 rows=499997 width=24) (actual time=10.747..1810.501 rows=500000 loops=1)
         Buffers: shared hit=7605 read=47951
 Planning Time: 0.227 ms
 Execution Time: 2531.740 ms
(7 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_columnar GROUP BY c00;
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=3997.69..4000.69 rows=200 width=72) (actual time=221.337..221.629 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=640
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..247.69 rows=500000 width=24) (actual time=6.564..113.139 rows=500000 loops=1)
         Columnar Projected Columns: c00, c29, c71
         Buffers: shared hit=640
 Planning Time: 0.428 ms
 Execution Time: 221.703 ms
(8 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_row GROUP BY c00;
                                                       QUERY PLAN                                                        
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64305.95..64313.45 rows=500 width=72) (actual time=1459.891..1460.182 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=7637 read=47919
   ->  Seq Scan on perf_row  (cost=0.00..60555.97 rows=499997 width=24) (actual time=2.391..832.459 rows=500000 loops=1)
         Buffers: shared hit=7637 read=47919
 Planning Time: 0.274 ms
 Execution Time: 1460.270 ms
(7 rows)
```

reduciing columns

```
postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT  AVG(c71) FROM perf_columnar GROUP BY c00;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=2665.13..2667.63 rows=200 width=40) (actual time=178.663..178.907 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=437
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..165.13 rows=500000 width=16) (actual time=2.186..81.926 rows=500000 loops=1)
         Columnar Projected Columns: c00, c71
         Buffers: shared hit=437
 Planning Time: 0.275 ms
 Execution Time: 179.298 ms
(8 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT  AVG(c71) FROM perf_columnar GROUP BY c00;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=2665.13..2667.63 rows=200 width=40) (actual time=178.785..179.026 rows=500 loops=1)
   Group Key: c00
   Buffers: shared hit=437
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..165.13 rows=500000 width=16) (actual time=2.071..81.067 rows=500000 loops=1)
         Columnar Projected Columns: c00, c71
         Buffers: shared hit=437
 Planning Time: 0.221 ms
 Execution Time: 179.102 ms
(8 rows)

postgres=# 
postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT  AVG(c79) FROM perf_columnar;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1332.57..1332.58 rows=1 width=32) (actual time=122.954..122.955 rows=1 loops=1)
   Buffers: shared hit=330
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..82.56 rows=500000 width=8) (actual time=1.680..82.640 rows=500000 loops=1)
         Columnar Projected Columns: c79
         Buffers: shared hit=330
 Planning Time: 0.483 ms
 Execution Time: 122.994 ms
(7 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT  AVG(c79) FROM perf_columnar;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1332.57..1332.58 rows=1 width=32) (actual time=144.118..144.119 rows=1 loops=1)
   Buffers: shared hit=330
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..82.56 rows=500000 width=8) (actual time=2.293..95.523 rows=500000 loops=1)
         Columnar Projected Columns: c79
         Buffers: shared hit=330
 Planning Time: 0.705 ms
 Execution Time: 144.171 ms
(7 rows)

postgres=# EXPLAIN (ANALYZE, BUFFERS) SELECT  AVG(c79) FROM perf_columnar;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1332.57..1332.58 rows=1 width=32) (actual time=111.086..111.087 rows=1 loops=1)
   Buffers: shared hit=330
   ->  Custom Scan (ColumnarScan) on perf_columnar  (cost=0.00..82.56 rows=500000 width=8) (actual time=2.335..72.921 rows=500000 loops=1)
         Columnar Projected Columns: c79
         Buffers: shared hit=330
 Planning Time: 0.374 ms
 Execution Time: 111.129 ms
(7 rows)
```
