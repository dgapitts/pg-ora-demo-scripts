## Demo02 Default SERIALIZATION in CRDB update single row in schedule table BLOCKS other transactions

In the previous demo we saw how the default postgres "read commited" isolation can lead to potentially confusioning results around overlapping (real time) transactions. 

Well in this demo we see in CRDB in CRDB update single row in schedule table BLOCKS selects/transactions i.e. in CRDB you probably need to keep your queries really short/atomic?





## Session/transaction 01 update single row in schedule table

```
root@localhost:26257/movr> begin;
BEGIN

Time: 0ms total (execution 0ms / network 0ms)

root@localhost:26257/movr  OPEN> select left(now()::string,19), * from schedules WHERE day = '2018-10-05';
         left         |    day     | doctor_id | on_call
----------------------+------------+-----------+----------
  2021-07-30 19:58:36 | 2018-10-05 |         1 |  true
  2021-07-30 19:58:36 | 2018-10-05 |         2 |  true
(2 rows)

Time: 2ms total (execution 2ms / network 0ms)

root@localhost:26257/movr  OPEN> UPDATE schedules SET on_call = false WHERE day = '2018-10-05' AND doctor_id = 1;
UPDATE 1

Time: 2ms total (execution 1ms / network 0ms)

root@localhost:26257/movr  OPEN> select left(now()::string,19), * from schedules WHERE day = '2018-10-05';
         left         |    day     | doctor_id | on_call
----------------------+------------+-----------+----------
  2021-07-30 19:58:36 | 2018-10-05 |         1 |  false
  2021-07-30 19:58:36 | 2018-10-05 |         2 |  true
(2 rows)

Time: 2ms total (execution 2ms / network 0ms)

root@localhost:26257/movr  OPEN> commit;
COMMIT

Time: 59ms total (execution 59ms / network 0ms)

root@localhost:26257/movr> select now();
                  now
---------------------------------------
  2021-07-30 20:04:13.824742+00:00:00
(1 row)

Time: 1ms total (execution 1ms / network 0ms)

root@localhost:26257/movr> 
```



## Session/transaction 02 regular SELECT on schedule table now blocked

```
~/projects/vagrant-centos7-cockroachdb $  cockroach sql --host localhost:26257 --insecure --database=movr
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v21.1.1 (x86_64-apple-darwin19, built 2021/05/24 15:00:00, go1.15.11) (same version as client)
# Cluster ID: acd10154-a5dd-41a9-bea6-b02f342660e7
#
# Enter \? for a brief introduction.
#
root@localhost:26257/movr> begin;
BEGIN

Time: 0ms total (execution 0ms / network 0ms)

root@localhost:26257/movr  OPEN> select left(now()::string,19), * from schedules WHERE day = '2018-10-05';
         left         |    day     | doctor_id | on_call
----------------------+------------+-----------+----------
  2021-07-30 20:00:07 | 2018-10-05 |         1 |  false
  2021-07-30 20:00:07 | 2018-10-05 |         2 |  true
(2 rows)

Time: 230.391s total (execution 230.390s / network 0.001s)

root@localhost:26257/movr  OPEN> select now();
                  now
---------------------------------------
  2021-07-30 20:00:07.815637+00:00:00
(1 row)

Time: 1ms total (execution 0ms / network 0ms)

root@localhost:26257/movr  OPEN> 
```
