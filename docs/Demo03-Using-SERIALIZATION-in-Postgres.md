## Demo03 Using SERIALIZATION in Postgres transactions start failing - due to read/write dependencies among transactions

In the previous demo we saw how the default postgres "read commited" isolation can lead to potentially confusioning results around overlapping (real time) transactions. 

In the previous demo we saw how in CockroachDB an update single row in schedule table BLOCKS selects/transactions i.e. in CRDB you probably need to keep your queries really short/atomic?

In this demo, I explore using SERIALIZABLE transactions in Postgres
* transaction/session 1 starts shortly ahead of transaction/session 2
* the session are updating consecutative rows in the same small table (I imagine the same/single data block)
* unlike CockroachDB neither trannsaction appears to hit blocking locks (around simple SELECT statements)
* session02 was successfully commited (first)
* however then session01 fails to commit "ERROR:  could not serialize access due to read/write dependencies among transactions"


## Session/transaction 01 update single row in schedule table 

```
dave=# begin;
BEGIN
dave=*#  set transaction ISOLATION LEVEL SERIALIZABLE;
SET
dave=*# show transaction ISOLATION LEVEL;
 transaction_isolation
-----------------------
 serializable
(1 row)

dave=*# select now();
              now
-------------------------------
 2021-08-03 20:54:10.129997+02
(1 row)

dave=*# select now();
              now
-------------------------------
 2021-08-03 20:54:10.129997+02
(1 row)

dave=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;

 count
-------
     1
(1 row)

dave=*# UPDATE schedules SET on_call = false WHERE day = '2018-10-05' AND doctor_id = 1;
UPDATE 1
dave=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count
-------
     1
(1 row)

dave=*# select now();
              now
-------------------------------
 2021-08-03 20:54:10.129997+02
(1 row)

dave=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count
-------
     1
(1 row)

dave=*# select now();
              now
-------------------------------
 2021-08-03 20:54:10.129997+02
(1 row)

dave=*# commit;
ERROR:  could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if retried.
dave=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;
 count
-------
     0
(1 row)

dave=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 2;
 count
-------
     1
(1 row)
```


## Session/transaction 02 update single row in schedule table 

```
dave=# BEGIN;
BEGIN
dave=*# set transaction ISOLATION LEVEL SERIALIZABLE;
SET
dave=*# show transaction ISOLATION LEVEL;
 transaction_isolation
-----------------------
 serializable
(1 row)

dave=*# select now();
             now
------------------------------
 2021-08-03 20:54:47.36523+02
(1 row)

dave=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 2;
 count
-------
     1
(1 row)

dave=*#  UPDATE schedules SET on_call = false WHERE day = '2018-10-05' AND doctor_id = 2;
UPDATE 1
dave=*# select now();
             now
------------------------------
 2021-08-03 20:54:47.36523+02
(1 row)

dave=*# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 2;
 count
-------
     1
(1 row)

dave=*# commit;
COMMIT
dave=# SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 2;
 count
-------
     1
(1 row)

```



