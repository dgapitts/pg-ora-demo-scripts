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
