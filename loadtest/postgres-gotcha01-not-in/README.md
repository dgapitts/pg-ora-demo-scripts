# Summary

This is a class postgres gotcha which I have demo via a very simple pgbench dataset:
* postgres bad plan - NOT IN
* postgres good plan - NOT EXISTS

I've also copied the data into Oracle to show the equivalent plans in Oracle
* oracle NOT IN plan - very fast
* oracle NOT EXISTS plan - very fast

## Setup with pgbench (scale factor 9)

```
-bash-4.2$ grep bench1 ~/.pgpass
localhost:5432:*:bench1:***
-bash-4.2$ pgbench -i -s 9 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 900000 tuples (11%) done (elapsed 0.04 s, remaining 0.35 s)
200000 of 900000 tuples (22%) done (elapsed 0.09 s, remaining 0.32 s)
300000 of 900000 tuples (33%) done (elapsed 0.14 s, remaining 0.27 s)
400000 of 900000 tuples (44%) done (elapsed 0.18 s, remaining 0.23 s)
500000 of 900000 tuples (55%) done (elapsed 0.23 s, remaining 0.18 s)
600000 of 900000 tuples (66%) done (elapsed 0.27 s, remaining 0.14 s)
700000 of 900000 tuples (77%) done (elapsed 0.39 s, remaining 0.11 s)
800000 of 900000 tuples (88%) done (elapsed 0.50 s, remaining 0.06 s)
900000 of 900000 tuples (100%) done (elapsed 0.61 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
```

## Details - postgres good plan - NOT EXIST (without Materialize Subquery)

```
-bash-4.2$ cat postgres-gotcha01-not-in-pgbench-demo.sql
delete from pgbench_branches where bid in (998,999);
insert into pgbench_branches values (998,0,'dummy branch 998');
insert into pgbench_branches values (999,0,'dummy branch 999');
create index pgbench_accounts_bid on pgbench_accounts(bid);
explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

-bash-4.2$ psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX

explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);

                                                                               QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=5.54..5.55 rows=1 width=8) (actual time=0.272..0.272 rows=1 loops=1)
   Buffers: shared hit=15 read=20
   ->  Nested Loop Anti Join  (cost=0.42..5.54 rows=1 width=4) (actual time=0.267..0.270 rows=2 loops=1)
         Buffers: shared hit=15 read=20
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.09 rows=9 width=4) (actual time=0.005..0.010 rows=11 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.42..2483.76 rows=100000 width=4) (actual time=0.023..0.023 rows=1 loops=11)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=14 read=20
 Planning time: 0.447 ms
 Execution time: 0.334 ms
(12 rows)
```

# Details - postgres bad plan - NOT IN  (with Materialize Subquery)

```

-bash-4.2$ psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql

...

explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

                                                                                   QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=151426.55..151426.56 rows=1 width=8) (actual time=1099.608..1099.608 rows=1 loops=1)
   Buffers: shared hit=14 read=2450, temp read=7704 written=1539
   ->  Seq Scan on pgbench_branches  (cost=0.42..151426.54 rows=4 width=4) (actual time=953.373..1099.602 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 9
         Buffers: shared hit=14 read=2450, temp read=7704 written=1539
         SubPlan 1
           ->  Materialize  (cost=0.42..31400.42 rows=900000 width=4) (actual time=0.014..57.693 rows=490910 loops=11)
                 Buffers: shared hit=13 read=2450, temp read=7704 written=1539
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.42..23384.42 rows=900000 width=4) (actual time=0.007..109.876 rows=900000 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=13 read=2450
 Planning time: 0.058 ms
 Execution time: 1101.056 ms
(14 rows)

```




# Details Oracle

## transfer from postgres to oracle

### postgres export to csv

```
\copy (SELECT * FROM pgbench_branches) to 'pgbench_branches.csv' with csv
\copy (SELECT * FROM pgbench_accounts) to 'pgbench_accounts.csv' with csv
```

### oracle import of csv via sqlloader

setup scott as sysdba
```
conn / as sysdba
create tablespace SCOTT_DATA datafile '/home/oracle/dbf/ORACLE/scott_data.dbf' size 25M autoextend on maxsize 1000M;
create user scott identified by *** default tablespace SCOTT_DATA;
grant connect,resource to scott;
ALTER USER scott quota unlimited on scott_data;
@?/rdbms/admin/utlxplan.sql
@?/sqlplus/admin/plustrce.sql
GRANT plustrace TO scott;
```

create tables as scott/***

```
create table pgbench_branches (bid number, bbalance number, filler character(88), CONSTRAINT pgbench_branches_pk PRIMARY KEY (bid));
create table pgbench_accounts (aid number, bid number, bbalance number, filler character(88), CONSTRAINT pgbench_accounts_pk PRIMARY KEY (aid));
create index pgbench_accounts_bid on pgbench_accounts(bid);
```

load data via sqlloader ctl files

```
$ cat load_accounts.ctl
load data
infile pgbench_accounts.csv
into table pgbench_accounts
fields terminated by ','
(aid, bid, bbalance)

$ cat load_branches.ctl
load data
infile pgbench_branches.csv
into table pgbench_branches
fields terminated by ','
(bid, bbalance)

sqlldr scott/*** load_accounts.ctl
sqlldr scott/*** load_branches.ctl
```


## Details - oracle NOT IN plan - very fast

```
SQL> select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

COUNT(BID)
----------
         0

Elapsed: 00:00:00.02

Execution Plan
----------------------------------------------------------
Plan hash value: 1674807286

------------------------------------------------------------------------------------------------
| Id  | Operation               | Name                 | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT        |                      |     1 |    26 |    24   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE         |                      |     1 |    26 |            |          |
|*  2 |   FILTER                |                      |       |       |            |          |
|   3 |    NESTED LOOPS ANTI SNA|                      |     3 |    78 |    24  (92)| 00:00:01 |
|   4 |     INDEX FULL SCAN     | PGBENCH_BRANCHES_PK  |     3 |    39 |     1   (0)| 00:00:01 |
|*  5 |     INDEX RANGE SCAN    | PGBENCH_ACCOUNTS_BID |     1 |    13 |     1   (0)| 00:00:01 |
|*  6 |    TABLE ACCESS FULL    | PGBENCH_ACCOUNTS     |     7 |    91 |    22   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter( NOT EXISTS (SELECT 0 FROM "PGBENCH_ACCOUNTS" "PGBENCH_ACCOUNTS" WHERE
              "BID" IS NULL))
   5 - access("BID"="BID")
   6 - filter("BID" IS NULL)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
        635  consistent gets
          0  physical reads
          0  redo size
        543  bytes sent via SQL*Net to client
        551  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed


```

## Details - oracle NOT EXISTS plan - very fast

```
SQL> select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);

COUNT(BID)
----------
         0

Elapsed: 00:00:00.01

Execution Plan
----------------------------------------------------------
Plan hash value: 1650890366

-------------------------------------------------------------------------------------------
| Id  | Operation          | Name                 | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |                      |     1 |    26 |     2   (0)| 00:00:01 |
|   1 |  SORT AGGREGATE    |                      |     1 |    26 |            |          |
|   2 |   NESTED LOOPS ANTI|                      |     3 |    78 |     2   (0)| 00:00:01 |
|   3 |    INDEX FULL SCAN | PGBENCH_BRANCHES_PK  |     3 |    39 |     1   (0)| 00:00:01 |
|*  4 |    INDEX RANGE SCAN| PGBENCH_ACCOUNTS_BID |     1 |    13 |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("ACCOUNT"."BID"="BRANCH"."BID")

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          9  consistent gets
          0  physical reads
          0  redo size
        543  bytes sent via SQL*Net to client
        551  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

```

## Appendix - repeat postgres test above but with scale factor 1, 2, 3, 5, 10 and 20 - performance problems grow exponentially 

```
-bash-4.2$ pgbench -i -s 1 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 100000 tuples (100%) done (elapsed 0.04 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
-bash-4.2$ psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX
                                                                                 QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2605.33..2605.34 rows=1 width=8) (actual time=31.585..31.585 rows=1 loops=1)
   Buffers: shared hit=279 read=275
   ->  Nested Loop Anti Join  (cost=0.29..2605.33 rows=1 width=4) (actual time=17.104..31.578 rows=2 loops=1)
         Join Filter: (account.bid = branch.bid)
         Rows Removed by Join Filter: 200000
         Buffers: shared hit=279 read=275
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.01 rows=1 width=4) (actual time=0.006..0.008 rows=3 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.29..2604.29 rows=100000 width=4) (actual time=0.022..6.062 rows=66667 loops=3)
               Heap Fetches: 0
               Buffers: shared hit=278 read=275
 Planning time: 0.384 ms
 Execution time: 31.656 ms
(13 rows)

                                                                              QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2855.31..2855.32 rows=1 width=8) (actual time=25.702..25.702 rows=1 loops=1)
   Buffers: shared hit=277
   ->  Seq Scan on pgbench_branches  (cost=2854.29..2855.30 rows=1 width=4) (actual time=25.696..25.697 rows=2 loops=1)
         Filter: (NOT (hashed SubPlan 1))
         Rows Removed by Filter: 1
         Buffers: shared hit=277
         SubPlan 1
           ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.29..2604.29 rows=100000 width=4) (actual time=0.010..8.941 rows=100000 loops=1)
                 Heap Fetches: 0
                 Buffers: shared hit=276
 Planning time: 0.175 ms
 Execution time: 25.754 ms
(12 rows)

-bash-4.2$ pgbench -i -s 2 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 200000 tuples (50%) done (elapsed 0.05 s, remaining 0.05 s)
200000 of 200000 tuples (100%) done (elapsed 0.09 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
-bash-4.2$ psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX
                                                                               QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2.00..2.01 rows=1 width=8) (actual time=0.094..0.094 rows=1 loops=1)
   Buffers: shared hit=8 read=6
   ->  Nested Loop Anti Join  (cost=0.42..2.00 rows=1 width=4) (actual time=0.088..0.091 rows=2 loops=1)
         Buffers: shared hit=8 read=6
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.02 rows=2 width=4) (actual time=0.005..0.005 rows=4 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.42..2486.42 rows=100000 width=4) (actual time=0.020..0.020 rows=0 loops=4)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=7 read=6
 Planning time: 0.338 ms
 Execution time: 0.156 ms
(12 rows)

                                                                                  QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7487.45..7487.46 rows=1 width=8) (actual time=121.745..121.745 rows=1 loops=1)
   Buffers: shared hit=7 read=544, temp read=515 written=342
   ->  Seq Scan on pgbench_branches  (cost=0.42..7487.45 rows=1 width=4) (actual time=87.107..121.738 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 2
         Buffers: shared hit=7 read=544, temp read=515 written=342
         SubPlan 1
           ->  Materialize  (cost=0.42..6986.42 rows=200000 width=4) (actual time=0.047..20.026 rows=125000 loops=4)
                 Buffers: shared hit=6 read=544, temp read=515 written=342
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.42..5204.42 rows=200000 width=4) (actual time=0.007..21.030 rows=200000 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=6 read=544
 Planning time: 0.049 ms
 Execution time: 122.189 ms
(14 rows)

-bash-4.2$ pgbench -i -s 3 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 300000 tuples (33%) done (elapsed 0.05 s, remaining 0.10 s)
200000 of 300000 tuples (66%) done (elapsed 0.12 s, remaining 0.06 s)
300000 of 300000 tuples (100%) done (elapsed 0.19 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
-bash-4.2$ psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX
                                                                               QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=2.51..2.52 rows=1 width=8) (actual time=0.116..0.116 rows=1 loops=1)
   Buffers: shared hit=9 read=8
   ->  Nested Loop Anti Join  (cost=0.42..2.51 rows=1 width=4) (actual time=0.110..0.112 rows=2 loops=1)
         Buffers: shared hit=9 read=8
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.03 rows=3 width=4) (actual time=0.005..0.008 rows=5 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.42..2483.76 rows=100000 width=4) (actual time=0.020..0.020 rows=1 loops=5)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=8 read=8
 Planning time: 0.378 ms
 Execution time: 0.188 ms
(12 rows)

                                                                                  QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=16834.47..16834.47 rows=1 width=8) (actual time=205.178..205.178 rows=1 loops=1)
   Buffers: shared hit=8 read=816, temp read=1029 written=513
   ->  Seq Scan on pgbench_branches  (cost=0.42..16834.46 rows=2 width=4) (actual time=153.048..205.171 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 3
         Buffers: shared hit=8 read=816, temp read=1029 written=513
         SubPlan 1
           ->  Materialize  (cost=0.42..10472.42 rows=300000 width=4) (actual time=0.013..26.636 rows=180001 loops=5)
                 Buffers: shared hit=7 read=816, temp read=1029 written=513
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.42..7800.42 rows=300000 width=4) (actual time=0.009..32.700 rows=300000 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=7 read=816
 Planning time: 0.071 ms
 Execution time: 205.738 ms
(14 rows)

-bash-4.2$ pgbench -i -s 10 -h localhost -p 5432 -U bench1  -d bench1;psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
creating tables...
100000 of 1000000 tuples (10%) done (elapsed 0.05 s, remaining 0.43 s)
200000 of 1000000 tuples (20%) done (elapsed 0.09 s, remaining 0.38 s)
300000 of 1000000 tuples (30%) done (elapsed 0.14 s, remaining 0.33 s)
400000 of 1000000 tuples (40%) done (elapsed 0.19 s, remaining 0.29 s)
500000 of 1000000 tuples (50%) done (elapsed 0.24 s, remaining 0.24 s)
600000 of 1000000 tuples (60%) done (elapsed 0.29 s, remaining 0.20 s)
700000 of 1000000 tuples (70%) done (elapsed 0.34 s, remaining 0.15 s)
800000 of 1000000 tuples (80%) done (elapsed 0.46 s, remaining 0.12 s)
900000 of 1000000 tuples (90%) done (elapsed 0.56 s, remaining 0.06 s)
1000000 of 1000000 tuples (100%) done (elapsed 0.68 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX
                                                                               QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=6.05..6.06 rows=1 width=8) (actual time=0.346..0.346 rows=1 loops=1)
   Buffers: shared hit=16 read=22
   ->  Nested Loop Anti Join  (cost=0.42..6.05 rows=1 width=4) (actual time=0.341..0.345 rows=2 loops=1)
         Buffers: shared hit=16 read=22
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.10 rows=10 width=4) (actual time=0.005..0.008 rows=12 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.42..2483.62 rows=100000 width=4) (actual time=0.027..0.027 rows=1 loops=12)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=15 read=22
 Planning time: 0.364 ms
 Execution time: 0.411 ms
(12 rows)

                                                                                    QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=186936.56..186936.57 rows=1 width=8) (actual time=1334.255..1334.255 rows=1 loops=1)
   Buffers: shared hit=15 read=2722, temp read=9414 written=1710
   ->  Seq Scan on pgbench_branches  (cost=0.42..186936.55 rows=5 width=4) (actual time=1149.078..1334.248 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 10
         Buffers: shared hit=15 read=2722, temp read=9414 written=1710
         SubPlan 1
           ->  Materialize  (cost=0.42..34887.43 rows=1000000 width=4) (actual time=0.015..63.924 rows=541668 loops=12)
                 Buffers: shared hit=14 read=2722, temp read=9414 written=1710
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.42..25980.42 rows=1000000 width=4) (actual time=0.007..112.087 rows=1000000 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=14 read=2722
 Planning time: 0.149 ms
 Execution time: 1335.845 ms
(14 rows)

-bash-4.2$ pgbench -i -s 20 -h localhost -p 5432 -U bench1  -d bench1;psql -U bench1 -f postgres-gotcha01-not-in-pgbench-demo.sql
creating tables...
100000 of 2000000 tuples (5%) done (elapsed 0.03 s, remaining 0.61 s)
200000 of 2000000 tuples (10%) done (elapsed 0.09 s, remaining 0.80 s)
300000 of 2000000 tuples (15%) done (elapsed 0.14 s, remaining 0.82 s)
400000 of 2000000 tuples (20%) done (elapsed 0.19 s, remaining 0.77 s)
500000 of 2000000 tuples (25%) done (elapsed 0.24 s, remaining 0.72 s)
600000 of 2000000 tuples (30%) done (elapsed 0.28 s, remaining 0.66 s)
700000 of 2000000 tuples (35%) done (elapsed 0.38 s, remaining 0.71 s)
800000 of 2000000 tuples (40%) done (elapsed 0.50 s, remaining 0.75 s)
900000 of 2000000 tuples (45%) done (elapsed 0.61 s, remaining 0.74 s)
1000000 of 2000000 tuples (50%) done (elapsed 0.70 s, remaining 0.70 s)
1100000 of 2000000 tuples (55%) done (elapsed 0.84 s, remaining 0.69 s)
1200000 of 2000000 tuples (60%) done (elapsed 0.95 s, remaining 0.63 s)
1300000 of 2000000 tuples (65%) done (elapsed 1.17 s, remaining 0.63 s)
1400000 of 2000000 tuples (70%) done (elapsed 1.28 s, remaining 0.55 s)
1500000 of 2000000 tuples (75%) done (elapsed 1.42 s, remaining 0.47 s)
1600000 of 2000000 tuples (80%) done (elapsed 1.53 s, remaining 0.38 s)
1700000 of 2000000 tuples (85%) done (elapsed 1.68 s, remaining 0.30 s)
1800000 of 2000000 tuples (90%) done (elapsed 1.79 s, remaining 0.20 s)
1900000 of 2000000 tuples (95%) done (elapsed 1.92 s, remaining 0.10 s)
2000000 of 2000000 tuples (100%) done (elapsed 2.10 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
DELETE 0
INSERT 0 1
INSERT 0 1
CREATE INDEX
                                                                               QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=11.15..11.16 rows=1 width=8) (actual time=0.521..0.521 rows=1 loops=1)
   Buffers: shared hit=26 read=42
   ->  Nested Loop Anti Join  (cost=0.43..11.14 rows=1 width=4) (actual time=0.515..0.518 rows=2 loops=1)
         Buffers: shared hit=26 read=42
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.20 rows=20 width=4) (actual time=0.006..0.015 rows=22 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts account  (cost=0.43..2483.23 rows=100000 width=4) (actual time=0.022..0.022 rows=1 loops=22)
               Index Cond: (bid = branch.bid)
               Heap Fetches: 0
               Buffers: shared hit=25 read=42
 Planning time: 0.406 ms
 Execution time: 0.584 ms
(12 rows)

                                                                                    QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=747611.70..747611.71 rows=1 width=8) (actual time=4191.513..4191.514 rows=1 loops=1)
   Buffers: shared hit=26 read=5444, temp read=35918 written=3420
   ->  Seq Scan on pgbench_branches  (cost=0.43..747611.68 rows=10 width=4) (actual time=3851.899..4191.506 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 20
         Buffers: shared hit=26 read=5444, temp read=35918 written=3420
         SubPlan 1
           ->  Materialize  (cost=0.43..69761.43 rows=2000000 width=4) (actual time=0.017..102.673 rows=1045455 loops=22)
                 Buffers: shared hit=25 read=5444, temp read=35918 written=3420
                 ->  Index Only Scan using pgbench_accounts_bid on pgbench_accounts  (cost=0.43..51948.43 rows=2000000 width=4) (actual time=0.008..223.147 rows=2000000 loops=1)
                       Heap Fetches: 0
                       Buffers: shared hit=25 read=5444
 Planning time: 0.157 ms
 Execution time: 4195.909 ms
(14 rows)
```
