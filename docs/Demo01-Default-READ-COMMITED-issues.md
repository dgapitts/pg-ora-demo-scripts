Demo01-Default-READ-COMMITED-issues

This is basically following https://www.cockroachlabs.com/docs/stable/demo-serializable.html but I've added "select now()" to show the how two sessions/transactions overlap

The point is two show how conflicting / overlapping transactions can lead to confusing results (no doctors available) with 
## Setup

```
[~/projects/pg-ora-demo-scripts/transaction-isolation-levels] # psql
psql (13.3 (Ubuntu 13.3-1.pgdg16.04+1), server 9.5.25)
Type "help" for help.

dpitts=# begin;
BEGIN
dpitts=*# \time on
invalid command \time
Try \? for help.
dpitts=*# \timing on
Timing is on.
dpitts=*# CREATE TABLE doctors (
dpitts(*#     id INT PRIMARY KEY,
dpitts(*#     name TEXT
dpitts(*# );
CREATE TABLE
Time: 40,158 ms
dpitts=*# CREATE TABLE schedules (
dpitts(*#     day DATE,
dpitts(*#     doctor_id INT REFERENCES doctors (id),
dpitts(*#     on_call BOOL,
dpitts(*#     PRIMARY KEY (day, doctor_id)
dpitts(*# );
CREATE TABLE
Time: 14,151 ms
dpitts=*# INSERT INTO doctors VALUES
dpitts-*#     (1, 'Abe'),
dpitts-*#     (2, 'Betty');
INSERT 0 2
Time: 2,374 ms
dpitts=*# INSERT INTO schedules VALUES
dpitts-*#     ('2018-10-01', 1, true),
dpitts-*#     ('2018-10-01', 2, true),
dpitts-*#     ('2018-10-02', 1, true),
dpitts-*#     ('2018-10-02', 2, true),
dpitts-*#     ('2018-10-03', 1, true),
dpitts-*#     ('2018-10-03', 2, true),
dpitts-*#     ('2018-10-04', 1, true),
dpitts-*#     ('2018-10-04', 2, true),
dpitts-*#     ('2018-10-05', 1, true),
dpitts-*#     ('2018-10-05', 2, true),
dpitts-*#     ('2018-10-06', 1, true),
dpitts-*#     ('2018-10-06', 2, true),
dpitts-*#     ('2018-10-07', 1, true),
dpitts-*#     ('2018-10-07', 2, true);
INSERT 0 14
Time: 6,272 ms
dpitts=*# 
dpitts=*# commit;
COMMIT
Time: 4,571 ms
dpitts=# select now();
              now              
-------------------------------
 2021-07-28 23:34:32.802224+02
(1 row)

Time: 1,598 ms
```

## Session / transaction 1

```
dpitts=# begin;
BEGIN
Time: 0,240 ms
dpitts=*# SELECT count(*) FROM schedules
dpitts-*#   WHERE on_call = true
dpitts-*#   AND day = '2018-10-05'
dpitts-*#   AND doctor_id != 1;
 count 
-------
     1
(1 row)

Time: 5,347 ms
dpitts=*# select now();
              now              
-------------------------------
 2021-07-28 23:35:37.877623+02
(1 row)

Time: 0,242 ms
dpitts=*# UPDATE schedules SET on_call = false
dpitts-*#   WHERE day = '2018-10-05'
dpitts-*#   AND doctor_id = 1;
UPDATE 1
Time: 0,592 ms
dpitts=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count 
-------
     1
(1 row)

Time: 0,857 ms
dpitts=*# select now();
              now              
-------------------------------
 2021-07-28 23:35:37.877623+02
(1 row)

Time: 0,333 ms
dpitts=*# commit;
COMMIT
Time: 3,948 ms
dpitts=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count 
-------
     1
(1 row)

Time: 0,713 ms
dpitts=# select now();
             now              
------------------------------
 2021-07-28 23:38:47.75126+02
(1 row)

Time: 0,318 ms
dpitts=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count 
-------
     0
(1 row)

Time: 0,647 ms
dpitts=# 

```

## Session / transaction 2
```
[~/projects/pg-ora-demo-scripts/transaction-isolation-levels] # psql 
psql (13.3 (Ubuntu 13.3-1.pgdg16.04+1), server 9.5.25)
Type "help" for help.

dpitts=# select now();
             now              
------------------------------
 2021-07-28 23:36:16.59677+02
(1 row)

dpitts=# begin;
BEGIN
dpitts=*# SELECT count(*) FROM schedules
dpitts-*#   WHERE on_call = true
dpitts-*#   AND day = '2018-10-05'
dpitts-*#   AND doctor_id != 2;
 count 
-------
     1
(1 row)

dpitts=*# select now();
              now              
-------------------------------
 2021-07-28 23:36:24.197316+02
(1 row)

dpitts=*# UPDATE schedules SET on_call = false
dpitts-*#   WHERE day = '2018-10-05'
dpitts-*#   AND doctor_id = 2;
UPDATE 1
dpitts=*# select now();
              now              
-------------------------------
 2021-07-28 23:36:24.197316+02
(1 row)

dpitts=*# commit;
COMMIT
dpitts=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 2;
 count 
-------
     0
(1 row)

dpitts=# 
```

