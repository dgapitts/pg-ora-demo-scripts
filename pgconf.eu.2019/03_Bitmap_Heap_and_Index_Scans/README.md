## Step 03 Bitmap Heap and Index Scans


We're filering on two columns i.e. id and salary, but an index on salary we end up Seq Scan on table (t_test):
```
milano2019=> \timing on
Timing is on.
milano2019=>  explain analyze select * from t_test where id < 1000 or salary = 10;
                                                 QUERY PLAN
-------------------------------------------------------------------------------------------------------------
 Seq Scan on t_test  (cost=0.00..179261.01 rows=994 width=21) (actual time=0.049..2575.385 rows=999 loops=1)
   Filter: ((id < 1000) OR (salary = '10'::numeric))
   Rows Removed by Filter: 8387609
 Planning Time: 0.364 ms
 Execution Time: 2576.782 ms
(5 rows)

Time: 2579.062 ms (00:02.579)
```


also adding verbose

```
milano2019=> \h explain
Command:     EXPLAIN
Description: show the execution plan of a statement
Syntax:
EXPLAIN [ ( option [, ...] ) ] statement
EXPLAIN [ ANALYZE ] [ VERBOSE ] statement

where option can be one of:

    ANALYZE [ boolean ]
    VERBOSE [ boolean ]
    COSTS [ boolean ]
    BUFFERS [ boolean ]
    TIMING [ boolean ]
    SUMMARY [ boolean ]
    FORMAT { TEXT | XML | JSON | YAML }

milano2019=>  explain analyze verbose select * from t_test where id < 1000 or salary = 10;
                                                     QUERY PLAN
--------------------------------------------------------------------------------------------------------------------
 Seq Scan on public.t_test  (cost=0.00..179261.01 rows=994 width=21) (actual time=0.013..1272.114 rows=999 loops=1)
   Output: id, name, salary
   Filter: ((t_test.id < 1000) OR (t_test.salary = '10'::numeric))
   Rows Removed by Filter: 8387609
 Planning Time: 0.153 ms
 Execution Time: 1272.219 ms
(6 rows)

Time: 1272.749 ms (00:01.273)
```
Note the "Rows Removed by Filter: 8387609" i.e. 99.99% of rows (the actual rows returned is 999).

So adding an index:

```
milano2019=> create index t_test_salary on t_test(salary);
CREATE INDEX
Time: 10135.572 ms (00:10.136)
```

we end with a plan which takes just 3.2ms (and not 1272ms as above)

```
milano2019=>  explain analyze verbose select * from t_test where id < 1000 or salary = 10;
                                                          QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on public.t_test  (cost=24.82..3578.51 rows=994 width=21) (actual time=2.502..3.166 rows=999 loops=1)
   Output: id, name, salary
   Recheck Cond: ((t_test.id < 1000) OR (t_test.salary = '10'::numeric))
   Heap Blocks: exact=7
   ->  BitmapOr  (cost=24.82..24.82 rows=994 width=0) (actual time=2.481..2.481 rows=0 loops=1)
         ->  Bitmap Index Scan on t_test_uid  (cost=0.00..19.88 rows=993 width=0) (actual time=2.108..2.109 rows=999 loops=1)
               Index Cond: (t_test.id < 1000)
         ->  Bitmap Index Scan on t_test_salary  (cost=0.00..4.44 rows=1 width=0) (actual time=0.371..0.371 rows=0 loops=1)
               Index Cond: (t_test.salary = '10'::numeric)
 Planning Time: 11.679 ms
 Execution Time: 3.288 ms
(11 rows)

Time: 15.521 ms
```

and as we make this more select e.g. returning just 99 rows, it gets even faster:

```
milano2019=>  explain analyze verbose select * from t_test where id < 100 or salary = 10;
                                                         QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on public.t_test  (cost=9.66..394.36 rows=99 width=21) (actual time=0.017..0.023 rows=99 loops=1)
   Output: id, name, salary
   Recheck Cond: ((t_test.id < 100) OR (t_test.salary = '10'::numeric))
   Heap Blocks: exact=1
   ->  BitmapOr  (cost=9.66..9.66 rows=99 width=0) (actual time=0.012..0.012 rows=0 loops=1)
         ->  Bitmap Index Scan on t_test_uid  (cost=0.00..5.17 rows=98 width=0) (actual time=0.006..0.006 rows=99 loops=1)
               Index Cond: (t_test.id < 100)
         ->  Bitmap Index Scan on t_test_salary  (cost=0.00..4.44 rows=1 width=0) (actual time=0.006..0.006 rows=0 loops=1)
               Index Cond: (t_test.salary = '10'::numeric)
 Planning Time: 0.089 ms
 Execution Time: 0.043 ms
(11 rows)
```

and as we make this more select e.g. returning just 9 rows, it gets marginally faster:

```
Time: 0.425 ms
milano2019=>  explain analyze verbose select * from t_test where id < 10 or salary = 10;
                                                         QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on public.t_test  (cost=8.95..48.68 rows=10 width=21) (actual time=0.016..0.018 rows=9 loops=1)
   Output: id, name, salary
   Recheck Cond: ((t_test.id < 10) OR (t_test.salary = '10'::numeric))
   Heap Blocks: exact=1
   ->  BitmapOr  (cost=8.95..8.95 rows=10 width=0) (actual time=0.013..0.013 rows=0 loops=1)
         ->  Bitmap Index Scan on t_test_uid  (cost=0.00..4.50 rows=9 width=0) (actual time=0.004..0.004 rows=9 loops=1)
               Index Cond: (t_test.id < 10)
         ->  Bitmap Index Scan on t_test_salary  (cost=0.00..4.44 rows=1 width=0) (actual time=0.009..0.009 rows=0 loops=1)
               Index Cond: (t_test.salary = '10'::numeric)
 Planning Time: 0.127 ms
 Execution Time: 0.041 ms
(11 rows)

Time: 0.532 ms
```

Lastly for completeness the table definition and index sizes

```
Time: 40.319 ms
milano2019=> \d t_test
                                     Table "public.t_test"
 Column |         Type          | Collation | Nullable |                Default
--------+-----------------------+-----------+----------+----------------------------------------
 id     | integer               |           | not null | nextval('t_test_id_seq'::regclass)
 name   | character varying(20) |           | not null |
 salary | numeric               |           |          | (random() * (10000)::double precision)
Indexes:
    "t_test_uid" UNIQUE, btree (id)
    "t_test_name" btree (name)
    "t_test_name_excluding" btree (name) WHERE name::text <> ALL (ARRAY['dave'::character varying, 'thomas'::character varying]::text[])
    "t_test_salary" btree (salary)

milano2019=> \di+
                                  List of relations
 Schema |         Name          | Type  | Owner  | Table  |    Size    | Description
--------+-----------------------+-------+--------+--------+------------+-------------
 public | foo_id                | index | pgconf | foo    | 16 kB      |
 public | foo_name              | index | pgconf | foo    | 32 kB      |
 public | t_test_name           | index | pgconf | t_test | 180 MB     |
 public | t_test_name_excluding | index | pgconf | t_test | 8192 bytes |
 public | t_test_salary         | index | pgconf | t_test | 252 MB     |
 public | t_test_uid            | index | pgconf | t_test | 180 MB     |
(6 rows)
```
