# Summary

This postgres gotcha is actually also an issue in Oracle and technically is bad/inefficient SQL by the developer, an inefficient existence check over two or more tables.

I've included the Oracle optimizer details below ie the good and bad execution plans.

# Details - Postgres

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

## Details - postgres bad plan - regular UNION (with sort and data deduplication)

```
bench1=> explain (analyze, buffers) (select 1 from pgbench_branches UNION  select 1 from pgbench_accounts) limit 1;
                                                                                    QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=42195.68..42195.69 rows=1 width=4) (actual time=130.374..130.377 rows=1 loops=1)
   Buffers: shared hit=824, temp read=1 written=513
   ->  Unique  (cost=42195.68..43695.70 rows=300003 width=4) (actual time=130.372..130.372 rows=1 loops=1)
         Buffers: shared hit=824, temp read=1 written=513
         ->  Sort  (cost=42195.68..42945.69 rows=300003 width=4) (actual time=130.372..130.372 rows=1 loops=1)
               Sort Key: (1)
               Sort Method: external sort  Disk: 4104kB
               Buffers: shared hit=824, temp read=1 written=513
               ->  Append  (cost=0.00..10801.48 rows=300003 width=4) (actual time=0.009..63.817 rows=300003 loops=1)
                     Buffers: shared hit=824
                     ->  Seq Scan on pgbench_branches  (cost=0.00..1.03 rows=3 width=4) (actual time=0.009..0.009 rows=3 loops=1)
                           Buffers: shared hit=1
                     ->  Index Only Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7800.42 rows=300000 width=4) (actual time=0.084..38.963 rows=300000 loops=1)
                           Heap Fetches: 0
                           Buffers: shared hit=823
 Planning time: 0.089 ms
 Execution time: 131.226 ms
(17 rows)
```

## Details - postgres good plan - UNION ALL (no sort operation and deduplication of data)

```
bench1=> explain (analyze, buffers) (select 1 from pgbench_branches UNION ALL select 1 from pgbench_accounts) limit 1;
                                                               QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..0.03 rows=1 width=4) (actual time=0.009..0.010 rows=1 loops=1)
   Buffers: shared hit=1
   ->  Append  (cost=0.00..7801.45 rows=300003 width=4) (actual time=0.008..0.008 rows=1 loops=1)
         Buffers: shared hit=1
         ->  Seq Scan on pgbench_branches  (cost=0.00..1.03 rows=3 width=4) (actual time=0.007..0.007 rows=1 loops=1)
               Buffers: shared hit=1
         ->  Index Only Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.42..7800.42 rows=300000 width=4) (never executed)
               Heap Fetches: 0
 Planning time: 0.087 ms
 Execution time: 0.027 ms
(10 rows)
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


## Details - oracle bad plan - regular UNION (with sort and data deduplication)

```
SQL> select * from (select 1 from pgbench_branches UNION  select 1 from pgbench_accounts) where rownum < 2;

         1
----------
         1

Elapsed: 00:00:00.05

Execution Plan
----------------------------------------------------------
Plan hash value: 2330842441

-----------------------------------------------------------------------------------------------------
| Id  | Operation             | Name                | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT      |                     |     1 |     3 |       |   673   (2)| 00:00:01 |
|*  1 |  COUNT STOPKEY        |                     |       |       |       |            |          |
|   2 |   VIEW                |                     |   315K|   924K|       |   673   (2)| 00:00:01 |
|*  3 |    SORT UNIQUE STOPKEY|                     |   315K|       |  1248K|   673   (2)| 00:00:01 |
|   4 |     UNION-ALL         |                     |       |       |       |            |          |
|   5 |      INDEX FULL SCAN  | PGBENCH_BRANCHES_PK |     3 |       |       |     1   (0)| 00:00:01 |
|   6 |      INDEX FULL SCAN  | PGBENCH_ACCOUNTS_PK |   315K|       |       |    62   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(ROWNUM<2)
   3 - filter(ROWNUM<2)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
        564  consistent gets
          0  physical reads
          0  redo size
        535  bytes sent via SQL*Net to client
        551  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          1  sorts (memory)
          0  sorts (disk)
          1  rows processed
```

## Details - oracle good plan - UNION ALL (no sort operation and deduplication of data)

```
SQL> select * from (select 1 from pgbench_branches UNION ALL  select 1 from pgbench_accounts) where rownum < 2;

         1
----------
         1

Elapsed: 00:00:00.00

Execution Plan
----------------------------------------------------------
Plan hash value: 3634172636

------------------------------------------------------------------------------------------
| Id  | Operation          | Name                | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |                     |     1 |     3 |     2   (0)| 00:00:01 |
|*  1 |  COUNT STOPKEY     |                     |       |       |            |          |
|   2 |   VIEW             |                     |   315K|   924K|     2   (0)| 00:00:01 |
|   3 |    UNION-ALL       |                     |       |       |            |          |
|   4 |     INDEX FULL SCAN| PGBENCH_BRANCHES_PK |     3 |       |     1   (0)| 00:00:01 |
|   5 |     INDEX FULL SCAN| PGBENCH_ACCOUNTS_PK |   315K|       |     1   (0)| 00:00:01 |
------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(ROWNUM<2)

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          1  consistent gets
          0  physical reads
          0  redo size
        535  bytes sent via SQL*Net to client
        551  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed
```
