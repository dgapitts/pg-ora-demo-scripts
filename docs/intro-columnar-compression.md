## Introducing Columnar Compression

Ref https://www.citusdata.com/blog/2021/03/06/citus-10-columnar-compression-for-postgres/ 

```
postgres=# CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION
postgres=# CREATE TABLE simple_row(i INT8);
CREATE TABLE
postgres=# CREATE TABLE simple_columnar(i INT8) USING columnar;
CREATE TABLE
postgres=# INSERT INTO simple_row SELECT generate_series(1,100000);
INSERT 0 100000
postgres=# INSERT INTO simple_columnar SELECT generate_series(1,100000);
INSERT 0 100000
```


ColumnarScan appears significantly cheaper than "traditional Seq Scan"
```
postgres=# explain analyze SELECT AVG(i) FROM simple_row;
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1693.00..1693.01 rows=1 width=32) (actual time=29.061..29.062 rows=1 loops=1)
   ->  Seq Scan on simple_row  (cost=0.00..1443.00 rows=100000 width=8) (actual time=0.023..15.836 rows=100000 loops=1)
 Planning Time: 0.680 ms
 Execution Time: 29.238 ms
(4 rows)

postgres=# explain analyze SELECT AVG(i) FROM simple_columnar;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=265.05..265.06 rows=1 width=32) (actual time=22.930..22.932 rows=1 loops=1)
   ->  Custom Scan (ColumnarScan) on simple_columnar  (cost=0.00..15.04 rows=100000 width=8) (actual time=0.827..13.849 rows=100000 loops=1)
         Columnar Projected Columns: i
 Planning Time: 0.343 ms
 Execution Time: 22.972 ms
(5 rows)
```

re-running (to help eliminate buffering factors)
```
postgres=# explain analyze SELECT AVG(i) FROM simple_row;
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1693.00..1693.01 rows=1 width=32) (actual time=19.693..19.694 rows=1 loops=1)
   ->  Seq Scan on simple_row  (cost=0.00..1443.00 rows=100000 width=8) (actual time=0.019..10.478 rows=100000 loops=1)
 Planning Time: 0.068 ms
 Execution Time: 19.730 ms
(4 rows)

postgres=# explain analyze SELECT AVG(i) FROM simple_columnar;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=265.05..265.06 rows=1 width=32) (actual time=19.147..19.148 rows=1 loops=1)
   ->  Custom Scan (ColumnarScan) on simple_columnar  (cost=0.00..15.04 rows=100000 width=8) (actual time=1.056..12.352 rows=100000 loops=1)
         Columnar Projected Columns: i
 Planning Time: 0.154 ms
 Execution Time: 19.183 ms
(5 rows)
```