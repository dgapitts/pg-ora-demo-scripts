## Step 02 Index Cardinality and Using a WHERE NOT IN clause (PARTAL INDEX)


This query is hard to effectively index, given 50% of the approx 8 million rows (rows=4184774) match "where name = 'dave'"
```
milano2019=> explain analyze select count(*) from t_test where name = 'dave';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=168749.96..168749.97 rows=1 width=8) (actual time=1399.321..1399.322 rows=1 loops=1)
   ->  Seq Scan on t_test  (cost=0.00..158288.03 rows=4184774 width=0) (actual time=0.360..1095.299 rows=4194304 loops=1)
         Filter: ((name)::text = 'dave'::text)
         Rows Removed by Filter: 4194304
 Planning Time: 0.075 ms
 Execution Time: 1399.355 ms
(6 rows)

Time: 1399.928 ms (00:01.400)
```

However if we are searching for names with low (or zero) cardinality e.g. "where name = 'dave'" is also slow

```
milano2019=> explain analyze select count(*) from t_test where name = 'dave2';
                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=158288.03..158288.04 rows=1 width=8) (actual time=751.911..751.911 rows=1 loops=1)
   ->  Seq Scan on t_test  (cost=0.00..158288.03 rows=1 width=0) (actual time=751.907..751.907 rows=0 loops=1)
         Filter: ((name)::text = 'dave2'::text)
         Rows Removed by Filter: 8388608
 Planning Time: 0.111 ms
 Execution Time: 751.949 ms
(6 rows)

Time: 752.563 ms
```

NB I reran the first query to see the affect of buffering (in this case not a significant difference)
```
milano2019=> explain analyze select count(*) from t_test where name = 'dave';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=168749.96..168749.97 rows=1 width=8) (actual time=1380.035..1380.035 rows=1 loops=1)
   ->  Seq Scan on t_test  (cost=0.00..158288.03 rows=4184774 width=0) (actual time=0.080..1073.100 rows=4194304 loops=1)
         Filter: ((name)::text = 'dave'::text)
         Rows Removed by Filter: 4194304
 Planning Time: 0.077 ms
 Execution Time: 1380.067 ms
(6 rows)

Time: 1380.548 ms (00:01.381)
```

### Adding a standard btree index on t_test(name) 

```
milano2019=> create index t_test_name on t_test(name);
CREATE INDEX
Time: 10725.741 ms (00:10.726)
milano2019=> explain analyze select count(*) from t_test where name = 'dave';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=168750.59..168750.60 rows=1 width=8) (actual time=1445.879..1445.879 rows=1 loops=1)
   ->  Seq Scan on t_test  (cost=0.00..158288.60 rows=4184797 width=0) (actual time=2.608..1140.848 rows=4194304 loops=1)
         Filter: ((name)::text = 'dave'::text)
         Rows Removed by Filter: 4194304
 Planning Time: 60.969 ms
 Execution Time: 1445.948 ms
(6 rows)

Time: 1507.649 ms (00:01.508)
```

this index is quite big i.e. 180MB on a 418MB table

```
milano2019=> \dt+
                    List of relations
 Schema |  Name  | Type  | Owner  |  Size  | Description
--------+--------+-------+--------+--------+-------------
 public | t_test | table | pgconf | 418 MB |
(1 row)
milano2019=> \di+
                           List of relations
 Schema |    Name     | Type  | Owner  | Table  |  Size  | Description
--------+-------------+-------+--------+--------+--------+-------------
 public | t_test_name | index | pgconf | t_test | 180 MB |
(1 row)
```

and how does if perform:
* not significantly fast for "where name = 'dave'" (i.e. 4 million out of 8 million rows case)
*  significantly fast for "where name = 'dave2'" (i.e. 0 out of 8 million rows case)

```
milano2019=> explain analyze select count(*) from t_test where name = 'dave';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=168750.59..168750.60 rows=1 width=8) (actual time=1446.948..1446.948 rows=1 loops=1)
   ->  Seq Scan on t_test  (cost=0.00..158288.60 rows=4184797 width=0) (actual time=0.100..1135.216 rows=4194304 loops=1)
         Filter: ((name)::text = 'dave'::text)
         Rows Removed by Filter: 4194304
 Planning Time: 0.124 ms
 Execution Time: 1446.980 ms
(6 rows)

Time: 1447.453 ms (00:01.447)
milano2019=> explain analyze select count(*) from t_test where name = 'dave2';
                                                          QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7.47..7.48 rows=1 width=8) (actual time=1.770..1.771 rows=1 loops=1)
   ->  Index Only Scan using t_test_name on t_test  (cost=0.43..7.47 rows=1 width=0) (actual time=1.765..1.765 rows=0 loops=1)
         Index Cond: (name = 'dave2'::text)
         Heap Fetches: 0
 Planning Time: 0.094 ms
 Execution Time: 3.714 ms
(6 rows)

Time: 95.802 ms
```

now lets build an index where name not in ('dave','thomas')
```
milano2019=> create index t_test_name_excluding on t_test(name) where name not in ('dave','thomas');'
CREATE INDEX
Time: 1079.634 ms (00:01.080)
```

this works really well and is small

```
milano2019=> explain analyze select count(*) from t_test where name = 'dave2';
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7.17..7.18 rows=1 width=8) (actual time=0.014..0.014 rows=1 loops=1)
   ->  Index Only Scan using t_test_name_excluding on t_test  (cost=0.12..7.16 rows=1 width=0) (actual time=0.010..0.010 rows=0 loops=1)
         Index Cond: (name = 'dave2'::text)
         Heap Fetches: 0
 Planning Time: 5.186 ms
 Execution Time: 0.087 ms
(6 rows)

Time: 6.005 ms
milano2019=> \di+
                                  List of relations
 Schema |         Name          | Type  | Owner  | Table  |    Size    | Description
--------+-----------------------+-------+--------+--------+------------+-------------
 public | t_test_name           | index | pgconf | t_test | 180 MB     |
 public | t_test_name_excluding | index | pgconf | t_test | 8192 bytes |
(2 rows)
```
