## FF and HOT updates - part 02 - simple example with fillfactor 100 - 3 updates and only 2 out of 3 are HOT 

### Backround

This is a rerun of test01 except we have updated one parameter 

### Test 02 - simple table, with spare space (100% fillfactor) plus no UPDATEs on INDEXed columns so 3 out of 3 HOT updates 

Below I step through a very simple scenario:
* simple table, with fillfactor=100 and 100 rows - spread over two pages (as per ctid details below)
* no UPDATEs on INDEXed columns 
* as per pg_stat_user_tables we have 2 out of 3 i.e. 66.7% HOT updates
* the very first update with 100FF requires the row to be moved to spare space in the second/final block
* the first update also releases a little space and which can be used for the 2nd and 3rd updates i.e. HOT updates


### Setup with fillfactor 90 - three HOT updates

```
~/projects/pg-ora-demo-scripts $ cat ./demo/t1_ff90.sql | sed 's/90/100/g' > ./demo/t1_ff100.sql
~/projects/pg-ora-demo-scripts $ cat ./demo/t1_ff100.sql
drop table t1_100;
CREATE TABLE t1_100 (
   v1  int,
   f1  varchar(30) default 'aaa123',
   f2  varchar(30) default 'baa123',
   f3  varchar(30) default 'caa123',
   f4  varchar(30) default 'daa123',
   f5  varchar(30) default 'eaa123',
   f6  varchar(30) default 'faa123',
   f7  varchar(30) default 'gaa123',
   f8  varchar(30) default 'haa123',
   f9  varchar(30) default 'iaa123'
) WITH (autovacuum_enabled = off, fillfactor=100);
create index concurrently t1_f1 on t1(f1);
create index concurrently t1_f2 on t1(f2);
INSERT INTO t1_100 (v1)  SELECT * FROM generate_series(0, 100) AS n;
SELECT ctid, v1, f1 from t1_100;
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
 update t1_100 set f3 = 'v2' where v1 = 2;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
update t1_100 set f3 = 'v2' where v1 = 3;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
SELECT ctid, v1, f1, f3 from t1_100 order by v1 limit 10;
update t1_100 set f1 = 'v2' where v1 = 4;
SELECT ctid, v1, f1, f3 from t1_100 order by v1 limit 10;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
```


running this, first we setup table and data
```
[pg13centos7:vagrant:/vagrant] #  psql -a -f t1_ff100.sql
drop table t1_100;
psql:t1_ff100.sql:1: ERROR:  table "t1_100" does not exist
CREATE TABLE t1_100 (
   v1  int,
   f1  varchar(30) default 'aaa123',
   f2  varchar(30) default 'baa123',
   f3  varchar(30) default 'caa123',
   f4  varchar(30) default 'daa123',
   f5  varchar(30) default 'eaa123',
   f6  varchar(30) default 'faa123',
   f7  varchar(30) default 'gaa123',
   f8  varchar(30) default 'haa123',
   f9  varchar(30) default 'iaa123'
) WITH (autovacuum_enabled = off, fillfactor=100);
CREATE TABLE
create index concurrently t1_f1 on t1(f1);
psql:t1_ff100.sql:14: ERROR:  relation "t1_f1" already exists
create index concurrently t1_f2 on t1(f2);
psql:t1_ff100.sql:15: ERROR:  relation "t1_f2" already exists
INSERT INTO t1_100 (v1)  SELECT * FROM generate_series(0, 100) AS n;
INSERT 0 101
```
and now the first page (first 81 rows) is fully packed (100%)
```
SELECT ctid, v1, f1 from t1_100;
  ctid  | v1  |   f1
--------+-----+--------
 (0,1)  |   0 | aaa123
 (0,2)  |   1 | aaa123
 (0,3)  |   2 | aaa123
 (0,4)  |   3 | aaa123
 (0,5)  |   4 | aaa123
 (0,6)  |   5 | aaa123
 (0,7)  |   6 | aaa123
 (0,8)  |   7 | aaa123
 (0,9)  |   8 | aaa123
 (0,10) |   9 | aaa123
 (0,11) |  10 | aaa123
 (0,12) |  11 | aaa123
 (0,13) |  12 | aaa123
 (0,14) |  13 | aaa123
 (0,15) |  14 | aaa123
 (0,16) |  15 | aaa123
 (0,17) |  16 | aaa123
 (0,18) |  17 | aaa123
 (0,19) |  18 | aaa123
 (0,20) |  19 | aaa123
 (0,21) |  20 | aaa123
 (0,22) |  21 | aaa123
 (0,23) |  22 | aaa123
 (0,24) |  23 | aaa123
 (0,25) |  24 | aaa123
 (0,26) |  25 | aaa123
 (0,27) |  26 | aaa123
 (0,28) |  27 | aaa123
 (0,29) |  28 | aaa123
 (0,30) |  29 | aaa123
 (0,31) |  30 | aaa123
 (0,32) |  31 | aaa123
 (0,33) |  32 | aaa123
 (0,34) |  33 | aaa123
 (0,35) |  34 | aaa123
 (0,36) |  35 | aaa123
 (0,37) |  36 | aaa123
 (0,38) |  37 | aaa123
 (0,39) |  38 | aaa123
 (0,40) |  39 | aaa123
 (0,41) |  40 | aaa123
 (0,42) |  41 | aaa123
 (0,43) |  42 | aaa123
 (0,44) |  43 | aaa123
 (0,45) |  44 | aaa123
 (0,46) |  45 | aaa123
 (0,47) |  46 | aaa123
 (0,48) |  47 | aaa123
 (0,49) |  48 | aaa123
 (0,50) |  49 | aaa123
 (0,51) |  50 | aaa123
 (0,52) |  51 | aaa123
 (0,53) |  52 | aaa123
 (0,54) |  53 | aaa123
 (0,55) |  54 | aaa123
 (0,56) |  55 | aaa123
 (0,57) |  56 | aaa123
 (0,58) |  57 | aaa123
 (0,59) |  58 | aaa123
 (0,60) |  59 | aaa123
 (0,61) |  60 | aaa123
 (0,62) |  61 | aaa123
 (0,63) |  62 | aaa123
 (0,64) |  63 | aaa123
 (0,65) |  64 | aaa123
 (0,66) |  65 | aaa123
 (0,67) |  66 | aaa123
 (0,68) |  67 | aaa123
 (0,69) |  68 | aaa123
 (0,70) |  69 | aaa123
 (0,71) |  70 | aaa123
 (0,72) |  71 | aaa123
 (0,73) |  72 | aaa123
 (0,74) |  73 | aaa123
 (0,75) |  74 | aaa123
 (0,76) |  75 | aaa123
 (0,77) |  76 | aaa123
 (0,78) |  77 | aaa123
 (0,79) |  78 | aaa123
 (0,80) |  79 | aaa123
 (0,81) |  80 | aaa123
 (1,1)  |  81 | aaa123
 (1,2)  |  82 | aaa123
 (1,3)  |  83 | aaa123
 (1,4)  |  84 | aaa123
 (1,5)  |  85 | aaa123
 (1,6)  |  86 | aaa123
 (1,7)  |  87 | aaa123
 (1,8)  |  88 | aaa123
 (1,9)  |  89 | aaa123
 (1,10) |  90 | aaa123
 (1,11) |  91 | aaa123
 (1,12) |  92 | aaa123
 (1,13) |  93 | aaa123
 (1,14) |  94 | aaa123
 (1,15) |  95 | aaa123
 (1,16) |  96 | aaa123
 (1,17) |  97 | aaa123
 (1,18) |  98 | aaa123
 (1,19) |  99 | aaa123
 (1,20) | 100 | aaa123
(101 rows)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         0 |             0
(1 row)
```

now run our first update is not HOT as we don't have spare space
```
 update t1_100 set f3 = 'v2' where v1 = 2;
UPDATE 1
select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             0
(1 row)

```

now run another update, now we can update the 3rd row in the first page, as the previous update released a bit of space (the 2nd row on the first page was moved to the 2nd page)
```
update t1_100 set f3 = 'v2' where v1 = 3;
UPDATE 1
select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         2 |             1
(1 row)

SELECT ctid, v1, f1, f3 from t1_100 order by v1 limit 10;
  ctid  | v1 |   f1   |   f3
--------+----+--------+--------
 (0,1)  |  0 | aaa123 | caa123
 (0,2)  |  1 | aaa123 | caa123
 (1,21) |  2 | aaa123 | v2
 (0,82) |  3 | aaa123 | v2
 (0,5)  |  4 | aaa123 | caa123
 (0,6)  |  5 | aaa123 | caa123
 (0,7)  |  6 | aaa123 | caa123
 (0,8)  |  7 | aaa123 | caa123
 (0,9)  |  8 | aaa123 | caa123
 (0,10) |  9 | aaa123 | caa123
(10 rows)
```

now run another update, again we can update the 4th row in the first page, as the previous update also released a bit of space (the old slot for row 3 data)
```

update t1_100 set f1 = 'v2' where v1 = 4;
UPDATE 1
SELECT ctid, v1, f1, f3 from t1_100 order by v1 limit 10;
  ctid  | v1 |   f1   |   f3
--------+----+--------+--------
 (0,1)  |  0 | aaa123 | caa123
 (0,2)  |  1 | aaa123 | caa123
 (1,21) |  2 | aaa123 | v2
 (0,82) |  3 | aaa123 | v2
 (0,83) |  4 | v2     | caa123
 (0,6)  |  5 | aaa123 | caa123
 (0,7)  |  6 | aaa123 | caa123
 (0,8)  |  7 | aaa123 | caa123
 (0,9)  |  8 | aaa123 | caa123
 (0,10) |  9 | aaa123 | caa123
(10 rows)

select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_100';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         3 |             2
(1 row)

```


