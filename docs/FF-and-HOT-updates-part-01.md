## FF and HOT updates - part 01 - examples with fillfactor 90


### Background 

I want to write up some notes on FF and HOT updates
* this is a good start point - nice summary https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/
* but I want to work through some of the details
* also expand on how to monitor and tune this 


### Setup with fillfactor 90

```
vagrant=> drop table t1;
DROP TABLE
vagrant=> CREATE TABLE t1 (
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
) WITH (autovacuum_enabled = off, fillfactor=90);
CREATE TABLE
vagrant=> INSERT INTO t1 (v1)  SELECT * FROM generate_series(0, 79) AS n;
INSERT 0 80
```

and initial 

```
vagrant=> SELECT ctid, v1, f1 from t1;
  ctid  | v1 |   f1
--------+----+--------
 (0,1)  |  0 | aaa123
 (0,2)  |  1 | aaa123
 (0,3)  |  2 | aaa123
 (0,4)  |  3 | aaa123
 (0,5)  |  4 | aaa123
 (0,6)  |  5 | aaa123
 (0,7)  |  6 | aaa123
 (0,8)  |  7 | aaa123
 (0,9)  |  8 | aaa123
 (0,10) |  9 | aaa123
 (0,11) | 10 | aaa123
 (0,12) | 11 | aaa123
 (0,13) | 12 | aaa123
 (0,14) | 13 | aaa123
 (0,15) | 14 | aaa123
 (0,16) | 15 | aaa123
 (0,17) | 16 | aaa123
 (0,18) | 17 | aaa123
 (0,19) | 18 | aaa123
 (0,20) | 19 | aaa123
 (0,21) | 20 | aaa123
 (0,22) | 21 | aaa123
 (0,23) | 22 | aaa123
 (0,24) | 23 | aaa123
 (0,25) | 24 | aaa123
 (0,26) | 25 | aaa123
 (0,27) | 26 | aaa123
 (0,28) | 27 | aaa123
 (0,29) | 28 | aaa123
 (0,30) | 29 | aaa123
 (0,31) | 30 | aaa123
 (0,32) | 31 | aaa123
 (0,33) | 32 | aaa123
 (0,34) | 33 | aaa123
 (0,35) | 34 | aaa123
 (0,36) | 35 | aaa123
 (0,37) | 36 | aaa123
 (0,38) | 37 | aaa123
 (0,39) | 38 | aaa123
 (0,40) | 39 | aaa123
 (0,41) | 40 | aaa123
 (0,42) | 41 | aaa123
 (0,43) | 42 | aaa123
 (0,44) | 43 | aaa123
 (0,45) | 44 | aaa123
 (0,46) | 45 | aaa123
 (0,47) | 46 | aaa123
 (0,48) | 47 | aaa123
 (0,49) | 48 | aaa123
 (0,50) | 49 | aaa123
 (0,51) | 50 | aaa123
 (0,52) | 51 | aaa123
 (0,53) | 52 | aaa123
 (0,54) | 53 | aaa123
 (0,55) | 54 | aaa123
 (0,56) | 55 | aaa123
 (0,57) | 56 | aaa123
 (0,58) | 57 | aaa123
 (0,59) | 58 | aaa123
 (0,60) | 59 | aaa123
 (0,61) | 60 | aaa123
 (0,62) | 61 | aaa123
 (0,63) | 62 | aaa123
 (0,64) | 63 | aaa123
 (0,65) | 64 | aaa123
 (0,66) | 65 | aaa123
 (0,67) | 66 | aaa123
 (0,68) | 67 | aaa123
 (0,69) | 68 | aaa123
 (0,70) | 69 | aaa123
 (0,71) | 70 | aaa123
 (0,72) | 71 | aaa123
 (0,73) | 72 | aaa123
 (1,1)  | 73 | aaa123
 (1,2)  | 74 | aaa123
 (1,3)  | 75 | aaa123
 (1,4)  | 76 | aaa123
 (1,5)  | 77 | aaa123
 (1,6)  | 78 | aaa123
 (1,7)  | 79 | aaa123
(80 rows)
```


now lets run 


vagrant=> select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         0 |             0
(1 row)

vagrant=> update t1 set f3 = 'v2' where v1 = 2;
UPDATE 1
vagrant=> select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             1
(1 row)

vagrant=> update t1 set f3 = 'v2' where v1 = 3;
UPDATE 1
vagrant=> select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         2 |             2
(1 row)

vagrant=> SELECT ctid, v1, f1 from t1 order by v1 limit 10;
  ctid  | v1 |   f1
--------+----+--------
 (0,1)  |  0 | aaa123
 (0,2)  |  1 | aaa123
 (0,74) |  2 | aaa123
 (0,75) |  3 | aaa123
 (0,5)  |  4 | aaa123
 (0,6)  |  5 | aaa123
 (0,7)  |  6 | aaa123
 (0,8)  |  7 | aaa123
 (0,9)  |  8 | aaa123
 (0,10) |  9 | aaa123
(10 rows)

vagrant=> SELECT ctid, v1, f1, f3 from t1 order by v1 limit 10;
  ctid  | v1 |   f1   |   f3
--------+----+--------+--------
 (0,1)  |  0 | aaa123 | caa123
 (0,2)  |  1 | aaa123 | caa123
 (0,74) |  2 | aaa123 | v2
 (0,75) |  3 | aaa123 | v2
 (0,5)  |  4 | aaa123 | caa123
 (0,6)  |  5 | aaa123 | caa123
 (0,7)  |  6 | aaa123 | caa123
 (0,8)  |  7 | aaa123 | caa123
 (0,9)  |  8 | aaa123 | caa123
 (0,10) |  9 | aaa123 | caa123
(10 rows)
```


```
vagrant=> update t1 set f1 = 'v2' where v1 = 4;
UPDATE 1
vagrant=> select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         3 |             2
(1 row)

vagrant=> SELECT ctid, v1, f1, f3 from t1 order by v1 limit 10;
  ctid  | v1 |   f1   |   f3
--------+----+--------+--------
 (0,1)  |  0 | aaa123 | caa123
 (0,2)  |  1 | aaa123 | caa123
 (0,74) |  2 | aaa123 | v2
 (0,75) |  3 | aaa123 | v2
 (0,76) |  4 | v2     | caa123
 (0,6)  |  5 | aaa123 | caa123
 (0,7)  |  6 | aaa123 | caa123
 (0,8)  |  7 | aaa123 | caa123
 (0,9)  |  8 | aaa123 | caa123
 (0,10) |  9 | aaa123 | caa123
(10 rows)
```


