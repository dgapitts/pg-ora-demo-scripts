# Demo03 unindexing FK example fixed by check script

## Summary 

The nice thing about following the "cybertec example regarding unindexing FKs", is that the missing index was correctly detect via demo/unindex_foreign_key_test.sql check script.

However I'm not sure it answers all the questions here (i.e. there will be Demo04 for FKs ...)

## Overview

The advice from [cybertec example regarding unindexing FKs](https://www.cybertec-postgresql.com/en/index-your-foreign-key/) is not black and white, it starts off with what the expected line
> A fact that is often ignored is that foreign keys need proper indexing to perform well.

but there is a sort caveat
> If the source table is small, you don’t need the index, because then a sequential scan is probably cheaper than an index scan anyway.



Also it doesn't mention locks? More on this later...

## Setup with unindexed foreign key - fairly extreme case

Following the cybertec example

```
~/projects/pg-ora-demo-scripts $ cat demo/unindex_foreign_key_test.sql
-- https://www.cybertec-postgresql.com/en/index-your-foreign-key/

drop table if exists target cascade;
drop table if exists source cascade;


-- to make the plans look simpler
SET max_parallel_workers_per_gather = 0;
-- to speed up CREATE INDEX
SET maintenance_work_mem = '512MB';
 
CREATE TABLE target (
   t_id integer NOT NULL,
   t_name text NOT NULL
);
INSERT INTO target (t_id, t_name)
   SELECT i, 'target ' || i
   FROM generate_series(1, 500001) AS i;
 
ALTER TABLE target
   ADD PRIMARY KEY (t_id);
 
CREATE INDEX ON target (t_name);
 
/* set hint bits and collect statistics */
VACUUM (ANALYZE) target;
 
CREATE TABLE source (
   s_id integer NOT NULL,
   t_id integer NOT NULL,
   s_name text NOT NULL
);
INSERT INTO source (s_id, t_id, s_name)
   SELECT i, (i - 1) % 500000 + 1, 'source ' || i
   FROM generate_series(1, 1000000) AS i;
 
ALTER TABLE source
   ADD PRIMARY KEY (s_id);
 
ALTER TABLE source
   ADD FOREIGN KEY (t_id) REFERENCES target;
 
/* set hint bits and collect statistics */
VACUUM (ANALYZE) source;

```

i.e.

```
~/projects/pg-ora-demo-scripts $ psql -f demo/unindex_foreign_key_test.sql 
psql:demo/unindex_foreign_key_test.sql:3: NOTICE:  drop cascades to constraint source_t_id_fkey on table source
DROP TABLE
DROP TABLE
SET
SET
CREATE TABLE
INSERT 0 500001
ALTER TABLE
CREATE INDEX
VACUUM
CREATE TABLE
INSERT 0 1000000
ALTER TABLE
ALTER TABLE
VACUUM
```

## Perf with unindexed foreign key 

* Expensive Seq Scan on public.source
* Parallelism is used (makes plan a bit harder to read)

```
dave=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT source.s_name FROM source JOIN target USING (t_id) WHERE target.t_name = 'target 42';
                                                                    QUERY PLAN                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1008.45..12639.08 rows=2 width=13) (actual time=9.030..276.118 rows=2 loops=1)
   Output: source.s_name
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=6480 read=3
   ->  Hash Join  (cost=8.45..11638.88 rows=1 width=13) (actual time=127.942..252.142 rows=1 loops=3)
         Output: source.s_name
         Inner Unique: true
         Hash Cond: (source.t_id = target.t_id)
         Buffers: shared hit=6480 read=3
         Worker 0:  actual time=135.686..245.804 rows=1 loops=1
           Buffers: shared hit=2131
         Worker 1:  actual time=245.824..245.827 rows=0 loops=1
           Buffers: shared hit=2170
         ->  Parallel Seq Scan on public.source  (cost=0.00..10536.67 rows=416667 width=17) (actual time=0.174..120.152 rows=333333 loops=3)
               Output: source.s_id, source.t_id, source.s_name
               Buffers: shared hit=6370
               Worker 0:  actual time=0.029..122.670 rows=326246 loops=1
                 Buffers: shared hit=2078
               Worker 1:  actual time=0.048..106.759 rows=332279 loops=1
                 Buffers: shared hit=2117
         ->  Hash  (cost=8.44..8.44 rows=1 width=4) (actual time=0.669..0.670 rows=1 loops=3)
               Output: target.t_id
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               Buffers: shared hit=11 read=3
               Worker 0:  actual time=0.164..0.165 rows=1 loops=1
                 Buffers: shared hit=5
               Worker 1:  actual time=0.162..0.164 rows=1 loops=1
                 Buffers: shared hit=5
               ->  Index Scan using target_t_name_idx on public.target  (cost=0.42..8.44 rows=1 width=4) (actual time=0.647..0.649 rows=1 loops=3)
                     Output: target.t_id
                     Index Cond: (target.t_name = 'target 42'::text)
                     Buffers: shared hit=11 read=3
                     Worker 0:  actual time=0.142..0.143 rows=1 loops=1
                       Buffers: shared hit=5
                     Worker 1:  actual time=0.144..0.145 rows=1 loops=1
                       Buffers: shared hit=5
 Planning:
   Buffers: shared hit=169 read=5 dirtied=3
 Planning Time: 4.692 ms
 Execution Time: 276.527 ms
(41 rows)
```

and again turnning parallelisation off

```
dave=# SET max_parallel_workers_per_gather = 0;
SET
dave=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT source.s_name FROM source JOIN target USING (t_id) WHERE target.t_name = 'target 42';
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=8.45..19003.47 rows=2 width=13) (actual time=0.085..257.560 rows=2 loops=1)
   Output: source.s_name
   Inner Unique: true
   Hash Cond: (source.t_id = target.t_id)
   Buffers: shared hit=6374
   ->  Seq Scan on public.source  (cost=0.00..16370.00 rows=1000000 width=17) (actual time=0.013..111.034 rows=1000000 loops=1)
         Output: source.s_id, source.t_id, source.s_name
         Buffers: shared hit=6370
   ->  Hash  (cost=8.44..8.44 rows=1 width=4) (actual time=0.028..0.029 rows=1 loops=1)
         Output: target.t_id
         Buckets: 1024  Batches: 1  Memory Usage: 9kB
         Buffers: shared hit=4
         ->  Index Scan using target_t_name_idx on public.target  (cost=0.42..8.44 rows=1 width=4) (actual time=0.019..0.020 rows=1 loops=1)
               Output: target.t_id
               Index Cond: (target.t_name = 'target 42'::text)
               Buffers: shared hit=4
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.439 ms
 Execution Time: 257.593 ms
(20 rows)
```


## Missing index check

```
~/projects/pg-ora-demo-scripts $ psql -f pgmon/unindex_foreign_key_expanded_display.sql 
Expanded display is on.
-[ RECORD 1 ]------------------+---------------------------------------------
referencing_tbl                | public.source
referencing_column             | t_id
existing_fk_on_referencing_tbl | source_t_id_fkey
referenced_tbl                 | public.target
referenced_column              | t_id
referencing_tbl_bytes          | 52183040
referenced_tbl_bytes           | 26017792
suggestion                     | CREATE INDEX ON public.source(t_id);
```

## Add recommended index

```
dave=# \timing on
Timing is on.
dave=# CREATE INDEX ON public.source(t_id);
CREATE INDEX
Time: 1309.838 ms (00:01.310)
```

## Perf after fixing unindexed foreign key

* No expensive `Seq Scan on public.source` now
* Replaced with cheap `Index Scan using source_t_id_id`

```
dave=# EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT source.s_name FROM source JOIN target USING (t_id) WHERE target.t_name = 'target 42';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.85..19.90 rows=2 width=13) (actual time=0.045..0.050 rows=2 loops=1)
   Output: source.s_name
   Buffers: shared hit=9
   ->  Index Scan using target_t_name_idx on public.target  (cost=0.42..8.44 rows=1 width=4) (actual time=0.015..0.015 rows=1 loops=1)
         Output: target.t_id, target.t_name
         Index Cond: (target.t_name = 'target 42'::text)
         Buffers: shared hit=4
   ->  Index Scan using source_t_id_idx on public.source  (cost=0.42..11.44 rows=2 width=17) (actual time=0.023..0.026 rows=2 loops=1)
         Output: source.s_id, source.t_id, source.s_name
         Index Cond: (source.t_id = target.t_id)
         Buffers: shared hit=5
 Planning:
   Buffers: shared hit=28 read=6
 Planning Time: 0.989 ms
 Execution Time: 0.091 ms
(15 rows)

Time: 1.771 ms
```
