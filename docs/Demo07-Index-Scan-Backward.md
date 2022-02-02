## Demo07 Index Scan Backward

As per this [stackoverflow index-scan-backward vs index-scan](https://stackoverflow.com/questions/5017327/index-scan-backward-vs-index-scan) post:
* this is not necessarily a bad thing
* but in some cases can become a performance bottleneck

### Simple use case - "schedules_pkey" (day, doctor_id)
```
dave=# \d schedules
               Table "public.schedules"
  Column   |  Type   | Collation | Nullable | Default 
-----------+---------+-----------+----------+---------
 day       | date    |           | not null | 
 doctor_id | integer |           | not null | 
 on_call   | boolean |           |          | 
Indexes:
    "schedules_pkey" PRIMARY KEY, btree (day, doctor_id)
Foreign-key constraints:
    "schedules_doctor_id_fkey" FOREIGN KEY (doctor_id) REFERENCES doctors(id)
```
not much data in this demo
```
dave=# select * from schedules;
    day     | doctor_id | on_call 
------------+-----------+---------
 2018-10-01 |         1 | t
 2018-10-01 |         2 | t
 2018-10-02 |         1 | t
 2018-10-02 |         2 | t
 2018-10-03 |         1 | t
 2018-10-03 |         2 | t
 2018-10-04 |         1 | t
 2018-10-04 |         2 | t
 2018-10-05 |         1 | t
 2018-10-06 |         1 | t
 2018-10-06 |         2 | t
 2018-10-07 |         1 | t
 2018-10-07 |         2 | t
 2018-10-05 |         2 | f
(14 rows)
```

to find the last (max) on call date for a particular doctor
```
dave=# select max(day) from schedules where doctor_id =1;
    max     
------------
 2018-10-07
(1 row)
```
this uses Index (Only) Scan Backward
```
dave=# explain select max(day) from schedules where doctor_id =1;
                                                  QUERY PLAN                                                  
--------------------------------------------------------------------------------------------------------------
 Result  (cost=5.79..5.80 rows=1 width=4)
   InitPlan 1 (returns $0)
     ->  Limit  (cost=0.15..5.79 rows=1 width=4)
           ->  Index Only Scan Backward using schedules_pkey on schedules  (cost=0.15..62.16 rows=11 width=4)
                 Index Cond: ((day IS NOT NULL) AND (doctor_id = 1))
(5 rows)
```

### Example with 5000000 rows - two variations of `Index Only Scan Backward` one cheap and one expensive


```
[pg13centos7:vagrant:~] # cat table_t1.sql
\timing on

drop table t1;

create table t1 as
WITH numbers AS (
  SELECT *
  FROM generate_series(1, 5000000)
)

SELECT generate_series as pk , round(generate_series * random() * 500) as f1, round(generate_series * random() * 1000) as f2
FROM numbers;

create index t1_f1_f2 on t1(f1,f2);

select * from t1 limit 10;

\d+ t1;

explain analyze select max(f2) from t1 where f1 = 42;

explain analyze select max(f1) from t1 where f2 = 42;
```

and strangely both these use 
* Index Only Scan Backward using t1_f1_f2 on t1 
* but the `where f1 = 42` is x1000 faster than `where f21 = 42`


```
[pg13centos7:vagrant:~] # psql -f table_t1.sql
Timing is on.
DROP TABLE
Time: 83.594 ms
SELECT 5000000
Time: 6577.590 ms (00:06.578)
CREATE INDEX
Time: 4776.987 ms (00:04.777)
 pk |  f1  |  f2
----+------+------
  1 |  245 |  313
  2 |  712 |  572
  3 | 1087 | 1736
  4 |   77 |  468
  5 | 1697 | 1717
  6 | 2411 | 1972
  7 |  940 |   39
  8 | 3232 | 7953
  9 | 2248 | 6419
 10 |  728 | 8988
(10 rows)

Time: 12.215 ms
                                         Table "public.t1"
 Column |       Type       | Collation | Nullable | Default | Storage | Stats target | Description
--------+------------------+-----------+----------+---------+---------+--------------+-------------
 pk     | integer          |           |          |         | plain   |              |
 f1     | double precision |           |          |         | plain   |              |
 f2     | double precision |           |          |         | plain   |              |
Indexes:
    "t1_f1_f2" btree (f1, f2)
Access method: heap

                                                                   QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------
 Result  (cost=3.34..3.35 rows=1 width=8) (actual time=0.554..0.555 rows=1 loops=1)
   InitPlan 1 (returns $0)
     ->  Limit  (cost=0.43..3.34 rows=1 width=8) (actual time=0.549..0.549 rows=0 loops=1)
           ->  Index Only Scan Backward using t1_f1_f2 on t1  (cost=0.43..72437.93 rows=24875 width=8) (actual time=0.548..0.548 rows=0 loops=1)
                 Index Cond: ((f1 = '42'::double precision) AND (f2 IS NOT NULL))
                 Heap Fetches: 0
 Planning Time: 0.109 ms
 Execution Time: 0.579 ms
(8 rows)

Time: 1.436 ms
                                                                      QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------
 Result  (cost=8.40..8.41 rows=1 width=8) (actual time=701.400..701.401 rows=1 loops=1)
   InitPlan 1 (returns $0)
     ->  Limit  (cost=0.43..8.40 rows=1 width=8) (actual time=701.396..701.397 rows=0 loops=1)
           ->  Index Only Scan Backward using t1_f1_f2 on t1  (cost=0.43..198083.18 rows=24875 width=8) (actual time=701.395..701.396 rows=0 loops=1)
                 Index Cond: ((f1 IS NOT NULL) AND (f2 = '42'::double precision))
                 Heap Fetches: 0
 Planning Time: 0.190 ms
 Execution Time: 701.477 ms
(8 rows)

Time: 702.237 ms
```

### Example with 5000000 rows (part two) - `Bitmap Index Scan` vs `Parallel Seq Scan`


* same t1 table and index creation on t1(f1,f2) 
* but now the queries are 
```
explain analyze select pk from t1 where f1 = 42;
explain analyze select pk from t1 where f2 = 42;
```
and now 
* the cheap query i.e. with better supporting index for `where f1 = 42` is using `Bitmap Index Scan`
* the more problematic query `where f2 = 42` switched to `Parallel Seq Scan` i.e. ignores the index


```
[pg13centos7:vagrant:~] # cat table_t1.sql
\timing on

drop table t1;

create table t1 as
WITH numbers AS (
  SELECT *
  FROM generate_series(1, 5000000)
)

SELECT generate_series as pk , round(generate_series * random() * 500) as f1, round(generate_series * random() * 1000) as f2
FROM numbers;

create index t1_f1_f2 on t1(f1,f2);
--create index t1_pk_f1_f2 on t1(f1,f2);

select * from t1 limit 10;

\d+ t1;

explain analyze select pk from t1 where f1 = 42;

explain analyze select pk from t1 where f2 = 42;
[pg13centos7:vagrant:~] # psql -f table_t1.sql
Timing is on.
DROP TABLE
Time: 78.874 ms
SELECT 5000000
Time: 5364.509 ms (00:05.365)
CREATE INDEX
Time: 5055.044 ms (00:05.055)
 pk |  f1  |  f2
----+------+------
  1 |   88 |  946
  2 |  150 | 1393
  3 |  293 | 1415
  4 | 1986 | 3845
  5 |  261 | 4751
  6 | 2390 |   11
  7 |    1 | 1551
  8 | 3054 | 7734
  9 | 4137 | 1387
 10 | 4804 | 5933
(10 rows)

Time: 1.219 ms
                                         Table "public.t1"
 Column |       Type       | Collation | Nullable | Default | Storage | Stats target | Description
--------+------------------+-----------+----------+---------+---------+--------------+-------------
 pk     | integer          |           |          |         | plain   |              |
 f1     | double precision |           |          |         | plain   |              |
 f2     | double precision |           |          |         | plain   |              |
Indexes:
    "t1_f1_f2" btree (f1, f2)
Access method: heap

                                                      QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on t1  (cost=582.18..32269.67 rows=25000 width=4) (actual time=0.558..0.558 rows=0 loops=1)
   Recheck Cond: (f1 = '42'::double precision)
   ->  Bitmap Index Scan on t1_f1_f2  (cost=0.00..575.93 rows=25000 width=0) (actual time=0.556..0.556 rows=0 loops=1)
         Index Cond: (f1 = '42'::double precision)
 Planning Time: 0.062 ms
 Execution Time: 0.570 ms
(6 rows)

Time: 1.411 ms
                                                      QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..61389.67 rows=25000 width=4) (actual time=300.866..373.584 rows=0 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on t1  (cost=0.00..57889.67 rows=10417 width=4) (actual time=259.181..259.182 rows=0 loops=3)
         Filter: (f2 = '42'::double precision)
         Rows Removed by Filter: 1666667
 Planning Time: 0.388 ms
 Execution Time: 373.602 ms
(8 rows)

Time: 375.080 ms
```