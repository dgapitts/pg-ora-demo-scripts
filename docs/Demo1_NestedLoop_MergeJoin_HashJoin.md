
## Demo of the three key execution plan join operations Nested Loop, [Sort] Merge Join and Hash Join Operarions 

### pg version - 12.5

```
[pg12centos7:postgres:~] # psql -c "select version();" 
                                                 version                                                 
---------------------------------------------------------------------------------------------------------
 PostgreSQL 12.5 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-39), 64-bit
(1 row)
```

### Server details 

2 fairly old / low spec CPUs
```
[pg12centos7:postgres:~] # grep 'processor\|model name' /proc/cpuinfo 
processor	: 0
model name	: Intel(R) Core(TM) i3-6100H CPU @ 2.70GHz
processor	: 1
model name	: Intel(R) Core(TM) i3-6100H CPU @ 2.70GHz
```

and not much memory 

```
[pg12centos7:postgres:~] # free -m
              total        used        free      shared  buff/cache   available
Mem:            486         108         165          35         212         329
Swap:          1535           0        1535
```


### Loading data - 300K rows in well under 1 second


```
[pg12centos7:postgres:~] # time pgbench -U postgres -d bench1 -i -s 3
dropping old tables...
creating tables...
generating data...
100000 of 300000 tuples (33%) done (elapsed 0.09 s, remaining 0.17 s)
200000 of 300000 tuples (66%) done (elapsed 0.19 s, remaining 0.10 s)
300000 of 300000 tuples (100%) done (elapsed 0.31 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.

real	0m0.678s
user	0m0.078s
sys	0m0.043s

```


### Reviewing shared_buffers and work_mem


```
postgres=# show shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)

postgres=# show work_mem;
 work_mem 
----------
 4MB
(1 row)
```


### load pgbench_history data (based on non overlapping pgbench_accounts.aid values)

A few notes here
* convert tid to pk with automatic sequence
* loading some pgbench_history data based on non overlapping pgbench_accounts.aid values
* I've scripted these commands...

```
[pg12centos7:postgres:~] # cat load_pgbench_history.sql
\set timing on

-- convert tid to pk with automatic sequence

alter table pgbench_history drop column tid;

alter table pgbench_history add column tid SERIAL PRIMARY KEY;

-- loading some pgbench_history data based on non overlapping pgbench_accounts.aid values
insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,5)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,7)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,11)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,13)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,17)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,19)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,23)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,29)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,31)=0 limit 1000);

insert into pgbench_history (aid, bid, delta, mtime, filler)
  (select aid, bid, 1, now(), substr(cast(now() as text),1,22) from pgbench_accounts where mod(aid,37)=0 limit 1000);

-- check that we have 10K rows

select count(*) from pgbench_history;
select count(distinct aid) from pgbench_history;
```


and running this




```
[pg12centos7:postgres:~] # psql -d bench1 -f load_pgbench_history.sql
ALTER TABLE
ALTER TABLE
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
INSERT 0 1000
 count 
-------
 10000
(1 row)

 count 
-------
  9987
(1 row)
```

bench1=# \set timing on
bench1=# analyze pgbench_accounts, pgbench_history;
ANALYZE
bench1=# \set timing on;
bench1=# analyze pgbench_accounts, pgbench_history;
ANALYZE


### Nested Loops


The `acc.aid = 5` here clause is highly selective and great for driving the query execution plan via a simple `Nested Loop`

```
bench1=# explain select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid = 5;
                                               QUERY PLAN                                                
---------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.42..262.45 rows=1 width=144)
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..8.44 rows=1 width=97)
         Index Cond: (aid = 5)
   ->  Seq Scan on pgbench_history hist  (cost=0.00..254.00 rows=1 width=47)
         Filter: ((aid < 100) AND (aid = 5))
(5 rows)
```

### [Sort] Merge Join 

The `Merge Join`  is chosen here as the `hist.aid < 100` and `acc.aid < 10` clauses return relatively small datasets which can be sorted and merged cheapily
```
bench1=# explain select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid < 10;
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Merge Join  (cost=229.83..234.85 rows=1 width=144)
   Merge Cond: (acc.aid = hist.aid)
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..8.60 rows=10 width=97)
         Index Cond: (aid < 10)
   ->  Sort  (cost=229.40..229.45 rows=19 width=47)
         Sort Key: hist.aid
         ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=19 width=47)
               Filter: (aid < 100)
(8 rows)
```
increasing the interim datasets slightly i.e. `hist.aid < 100` and `acc.aid < 100`: the optimizer still uses a `Merge Join` 

```
bench1=# explain select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid < 100;
                                                 QUERY PLAN                                                 
------------------------------------------------------------------------------------------------------------
 Merge Join  (cost=229.83..236.91 rows=1 width=144)
   Merge Cond: (acc.aid = hist.aid)
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..11.26 rows=105 width=97)
         Index Cond: (aid < 100)
   ->  Sort  (cost=229.40..229.45 rows=19 width=47)
         Sort Key: hist.aid
         ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=19 width=47)
               Filter: (aid < 100)
(8 rows)
```

###  Hash Join

increasing the interim datasets significantly i.e. `hist.aid < 10000` and `acc.aid < 100`:
* the interim datasets are too large to be held in memory 
* optimizer switches to a `Hash Join`

```
bench1=# explain select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 10000 and acc.aid < 100;
                                                    QUERY PLAN                                                    
------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=12.57..246.11 rows=1 width=144)
   Hash Cond: (hist.aid = acc.aid)
   ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=1730 width=47)
         Filter: (aid < 10000)
   ->  Hash  (cost=11.26..11.26 rows=105 width=97)
         ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..11.26 rows=105 width=97)
               Index Cond: (aid < 100)
(7 rows)
```









