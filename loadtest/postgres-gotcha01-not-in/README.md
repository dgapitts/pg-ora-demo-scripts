# Summary

This is a class postgres gotcha which I have demo via a very simple pgbench dataset:
* postgres bad plan - NOT IN
* postgres good plan - NOT EXISTS

I've also copied the data into Oracle to show the equivalent plans in Oracle
* oracle NOT IN plan - very fast
* oracle NOT EXISTS plan - very fast

## Setup with pgbench (scale factor 3)

```
-bash-4.2$ grep bench1 ~/.pgpass
localhost:5432:*:bench1:***
-bash-4.2$ pgbench -i -s 3 -h localhost -p 5432 -U bench1  -d bench1
creating tables...
100000 of 300000 tuples (33%) done (elapsed 0.04 s, remaining 0.08 s)
200000 of 300000 tuples (66%) done (elapsed 0.09 s, remaining 0.05 s)
300000 of 300000 tuples (100%) done (elapsed 0.16 s, remaining 0.00 s)
vacuum...
set primary keys...
done.
```

## Details - postgres bad plan - NOT IN

```
select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

                                                                 QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=7920.57..7920.58 rows=1 width=8) (actual time=208.799..208.799 rows=1 loops=1)
   Buffers: shared hit=4698 read=10061
   ->  Nested Loop Anti Join  (cost=0.00..7920.57 rows=1 width=4) (actual time=148.023..208.791 rows=2 loops=1)
         Join Filter: (account.bid = branch.bid)
\timing on
         Rows Removed by Join Filter: 900000
         Buffers: shared hit=4698 read=10061
         ->  Seq Scan on pgbench_branches branch  (cost=0.00..1.03 rows=3 width=4) (actual time=0.005..0.007 rows=5 loops=1)
               Buffers: shared hit=1
         ->  Seq Scan on pgbench_accounts account  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.011..23.121 rows=180001 loops=5)
               Buffers: shared hit=4697 read=10061
 Planning time: 0.378 ms
 Execution time: 208.889 ms
(12 rows)
```

# Details - postgres good plan - NOT EXISTS

```
select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);

                                                                 QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=17012.54..17012.55 rows=1 width=8) (actual time=215.329..215.329 rows=1 loops=1)
   Buffers: shared hit=2145 read=2775, temp read=1029 written=513
   ->  Seq Scan on pgbench_branches  (cost=0.00..17012.54 rows=2 width=4) (actual time=165.256..215.315 rows=2 loops=1)
         Filter: (NOT (SubPlan 1))
         Rows Removed by Filter: 3
         Buffers: shared hit=2145 read=2775, temp read=1029 written=513
         SubPlan 1
           ->  Materialize  (cost=0.00..10591.00 rows=300000 width=4) (actual time=0.019..28.571 rows=180001 loops=5)
                 Buffers: shared hit=2144 read=2775, temp read=1029 written=513
                 ->  Seq Scan on pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=4) (actual time=0.024..45.678 rows=300000 loops=1)
                       Buffers: shared hit=2144 read=2775
 Planning time: 0.089 ms
 Execution time: 216.341 ms
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
