## FF and HOT updates - part 03  -  added `explain (analyze,wal)`


### Background - rerunnning test01  

I've added `explain (analyze,wal)` to test01
* simple table, with fillfactor=90 and 100 rows - spread over two pages (as per ctid details below)
* no UPDATEs on INDEXed columns 
* as per pg_stat_user_tables we have 3 out of 3 i.e. 100% HOT updates

The results below are not quite as I expected ...  

### Test 03 - overview - only one of three UPDATEs triggered WAL !?

The first (HOT) UPDATE didn't log any WAL (which is a surprise)
```
explain (analyze,wal) update t1_90 set f3 = 'v2' where v1 = 2;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.044..0.045 rows=0 loops=1)
   WAL: records=1 bytes=73
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.010..0.023 rows=1 loops=1)
         Filter: (v1 = 2)
         Rows Removed by Filter: 100
 Planning Time: 0.083 ms
 Execution Time: 0.104 ms
(7 rows)
```

The second (HOT again) UPDATE did (i.e. `WAL: records=1 bytes=58`)

```
explain (analyze,wal) update t1_90 set f3 = 'v2' where v1 = 3;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.039..0.040 rows=0 loops=1)
   WAL: records=2 bytes=131
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.018..0.026 rows=1 loops=1)
         Filter: (v1 = 3)
         Rows Removed by Filter: 100
         WAL: records=1 bytes=58
 Planning Time: 0.034 ms
 Execution Time: 0.054 ms
(8 rows)
```

The third (HOT again) UPDATE did not

```
explain (analyze,wal) update t1_90 set f1 = 'v2' where v1 = 4;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.106..0.106 rows=0 loops=1)
   WAL: records=1 bytes=73
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.011..0.016 rows=1 loops=1)
         Filter: (v1 = 4)
         Rows Removed by Filter: 100
 Planning Time: 0.065 ms
 Execution Time: 0.123 ms
(7 rows)
```


## Full output


Setup...

```
[pg13centos7:vagrant:/vagrant] #  psql -a -f t1_ff90.sql
drop table t1_90;
DROP TABLE
CREATE TABLE t1_90 (
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
create index concurrently t1_f1 on t1(f1);
psql:t1_ff90.sql:14: ERROR:  relation "t1_f1" already exists
create index concurrently t1_f2 on t1(f2);
psql:t1_ff90.sql:15: ERROR:  relation "t1_f2" already exists
INSERT INTO t1_90 (v1)  SELECT * FROM generate_series(0, 100) AS n;
INSERT 0 101
SELECT ctid, v1, f1 from t1_90;
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
 (1,1)  |  73 | aaa123
 (1,2)  |  74 | aaa123
 (1,3)  |  75 | aaa123
 (1,4)  |  76 | aaa123
 (1,5)  |  77 | aaa123
 (1,6)  |  78 | aaa123
 (1,7)  |  79 | aaa123
 (1,8)  |  80 | aaa123
 (1,9)  |  81 | aaa123
 (1,10) |  82 | aaa123
 (1,11) |  83 | aaa123
 (1,12) |  84 | aaa123
 (1,13) |  85 | aaa123
 (1,14) |  86 | aaa123
 (1,15) |  87 | aaa123
 (1,16) |  88 | aaa123
 (1,17) |  89 | aaa123
 (1,18) |  90 | aaa123
 (1,19) |  91 | aaa123
 (1,20) |  92 | aaa123
 (1,21) |  93 | aaa123
 (1,22) |  94 | aaa123
 (1,23) |  95 | aaa123
 (1,24) |  96 | aaa123
 (1,25) |  97 | aaa123
 (1,26) |  98 | aaa123
 (1,27) |  99 | aaa123
 (1,28) | 100 | aaa123
(101 rows)
```

the run three UPDATE tests
```
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         0 |             0
(1 row)

explain (analyze,wal) update t1_90 set f3 = 'v2' where v1 = 2;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.044..0.045 rows=0 loops=1)
   WAL: records=1 bytes=73
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.010..0.023 rows=1 loops=1)
         Filter: (v1 = 2)
         Rows Removed by Filter: 100
 Planning Time: 0.083 ms
 Execution Time: 0.104 ms
(7 rows)

select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             1
(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             1
(1 row)

explain (analyze,wal) update t1_90 set f3 = 'v2' where v1 = 3;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.039..0.040 rows=0 loops=1)
   WAL: records=2 bytes=131
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.018..0.026 rows=1 loops=1)
         Filter: (v1 = 3)
         Rows Removed by Filter: 100
         WAL: records=1 bytes=58
 Planning Time: 0.034 ms
 Execution Time: 0.054 ms
(8 rows)

select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             1
(1 row)

SELECT ctid, v1, f1, f3 from t1_90 order by v1 limit 10;
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

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         1 |             1
(1 row)

explain (analyze,wal) update t1_90 set f1 = 'v2' where v1 = 4;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Update on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.106..0.106 rows=0 loops=1)
   WAL: records=1 bytes=73
   ->  Seq Scan on t1_90  (cost=0.00..11.38 rows=1 width=712) (actual time=0.011..0.016 rows=1 loops=1)
         Filter: (v1 = 4)
         Rows Removed by Filter: 100
 Planning Time: 0.065 ms
 Execution Time: 0.123 ms
(7 rows)

SELECT ctid, v1, f1, f3 from t1_90 order by v1 limit 10;
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

select pg_sleep(3);
 pg_sleep
----------

(1 row)

select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 n_tup_upd | n_tup_hot_upd
-----------+---------------
         3 |             3
(1 row)
```