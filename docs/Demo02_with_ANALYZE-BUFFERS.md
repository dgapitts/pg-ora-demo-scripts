
## Demo02 with ANALYZE,BUFFERS - again of the three key execution plan join operations Nested Loop, [Sort] Merge Join and Hash Join Operarions 

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
Mem:            486         111         117          56         257         305
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


### Nested Loops with (ANALYZE,BUFFERS) 


The `acc.aid = 5` here clause is highly selective and great for driving the query execution plan via a simple `Nested Loop`.

Also be adding (ANALYZE,BUFFERS)  we can see the row counts and original expected costs are fairly accurate:

```
bench1=# explain (ANALYZE,BUFFERS) select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid = 5;
                                                                    QUERY PLAN                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.42..262.45 rows=1 width=144) (actual time=0.282..4.535 rows=1 loops=1)
   Buffers: shared hit=108
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..8.44 rows=1 width=97) (actual time=0.228..0.230 rows=1 loops=1)
         Index Cond: (aid = 5)
         Buffers: shared hit=4
   ->  Seq Scan on pgbench_history hist  (cost=0.00..254.00 rows=1 width=47) (actual time=0.047..4.297 rows=1 loops=1)
         Filter: ((aid < 100) AND (aid = 5))
         Rows Removed by Filter: 9999
         Buffers: shared hit=104
 Planning Time: 0.272 ms
 Execution Time: 4.604 ms
(11 rows)

```

### [Sort] Merge Join 

The `Merge Join`  is chosen here as the `hist.aid < 100` and `acc.aid < 10` clauses return relatively small datasets which can be sorted and merged cheapily

Also be adding (ANALYZE,BUFFERS)  we can see the row counts and original expected costs are fairly accurate, although this does now standout `Sort  (cost=229.40..229.45 rows=19 width=47) (actual time=2.564..2.565 rows=2 loops=1)` i.e. 19 vs 2.

However with these relatively small datasets everything is basically fast

```
bench1=#  explain (ANALYZE,BUFFERS) select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid < 10;
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Merge Join  (cost=229.83..234.85 rows=1 width=144) (actual time=2.605..2.614 rows=1 loops=1)
   Merge Cond: (acc.aid = hist.aid)
   Buffers: shared hit=112
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..8.60 rows=10 width=97) (actual time=0.008..0.015 rows=9 loops=1)
         Index Cond: (aid < 10)
         Buffers: shared hit=4
   ->  Sort  (cost=229.40..229.45 rows=19 width=47) (actual time=2.564..2.565 rows=2 loops=1)
         Sort Key: hist.aid
         Sort Method: quicksort  Memory: 27kB
         Buffers: shared hit=108
         ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=19 width=47) (actual time=0.020..2.438 rows=19 loops=1)
               Filter: (aid < 100)
               Rows Removed by Filter: 9981
               Buffers: shared hit=104
 Planning Time: 0.591 ms
 Execution Time: 2.774 ms
(16 rows)

```
increasing the interim datasets slightly i.e. `hist.aid < 100` and `acc.aid < 100`: the optimizer still uses a `Merge Join`. Again be adding (ANALYZE,BUFFERS)  we can see the row counts and original expected costs are fairly accurate, now the top level stands-out `(cost=229.83..236.91 rows=1 width=144) (actual time=2.555..2.710 rows=19 loops=1)` i.e. 19 vs 1. Still with these relatively small datasets everything is basically fast 

```
bench1=# explain (ANALYZE,BUFFERS) select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 100 and acc.aid < 100;
                                                                      QUERY PLAN                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Merge Join  (cost=229.83..236.91 rows=1 width=144) (actual time=2.555..2.710 rows=19 loops=1)
   Merge Cond: (acc.aid = hist.aid)
   Buffers: shared hit=109
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..11.26 rows=105 width=97) (actual time=0.020..0.086 rows=96 loops=1)
         Index Cond: (aid < 100)
         Buffers: shared hit=5
   ->  Sort  (cost=229.40..229.45 rows=19 width=47) (actual time=2.518..2.523 rows=19 loops=1)
         Sort Key: hist.aid
         Sort Method: quicksort  Memory: 27kB
         Buffers: shared hit=104
         ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=19 width=47) (actual time=0.022..2.489 rows=19 loops=1)
               Filter: (aid < 100)
               Rows Removed by Filter: 9981
               Buffers: shared hit=104
 Planning Time: 0.493 ms
 Execution Time: 2.844 ms
(16 rows)

```

###  Hash Join

increasing the interim datasets significantly i.e. `hist.aid < 10000` and `acc.aid < 100`:
* the interim datasets are too large to be held in memory (not now 100% sure of this assertion?)
* optimizer switches to a `Hash Join`

Again be adding (ANALYZE,BUFFERS)  we can see the row counts and original expected costs are fairly accurate, now the top level stands-out `(cost=12.57..246.11 rows=1 width=144) (actual time=0.447..4.416 rows=19 loops=1)` i.e. 19 vs 1. Still with these relatively small datasets everything is basically fast 

```
bench1=# explain (ANALYZE,BUFFERS)  select * from pgbench_accounts acc, pgbench_history hist where acc.aid = hist.aid and hist.aid < 10000 and acc.aid < 100;
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=12.57..246.11 rows=1 width=144) (actual time=0.447..4.416 rows=19 loops=1)
   Hash Cond: (hist.aid = acc.aid)
   Buffers: shared hit=112
   ->  Seq Scan on pgbench_history hist  (cost=0.00..229.00 rows=1730 width=47) (actual time=0.131..3.525 rows=1731 loops=1)
         Filter: (aid < 10000)
         Rows Removed by Filter: 8269
         Buffers: shared hit=104
   ->  Hash  (cost=11.26..11.26 rows=105 width=97) (actual time=0.201..0.201 rows=99 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 21kB
         Buffers: shared hit=5
         ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts acc  (cost=0.42..11.26 rows=105 width=97) (actual time=0.039..0.109 rows=99 loops=1)
               Index Cond: (aid < 100)
               Buffers: shared hit=5
 Planning Time: 0.581 ms
 Execution Time: 4.503 ms
(15 rows)


```









