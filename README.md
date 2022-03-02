# pg-ora-demo-scripts overview

This pg-ora-demo-scripts project/repro is for basic postgres monitoring, simple load tests, interesting Postgres DBA edge cases and other demo exercises. It is especially aimed at Oracle DBA with comparisons to how Oracle handles such edge cases and some gotchas around migrating/moving from Postgres to Oracle.

note:
* each subfolder has it own README.md with setup instructions and details of various perf/monitoring issues
* the dgapitts/vagrant-postgres9.6 can be used to quickly build a postgres-on-linux VM 
* I will also work on a simple RDS/EC2 setup instructions, so you can run these tests in the AWS Cloud 

# pg-ora-demo-scripts details

## Already covered
* Rewriting this query with a NOT EXIST clause instead of NOT IN (Postgres specific gotcha and costs grow exponentially - demos with scale factors 1,2,3,5,10 and 20)
* UNION vs UNION ALL this a classic developer gotcha and similar perf issues on BOTH Postgres and Oracle, but watchout for minor manual pg-2-ora SQL conversions e.g. 'existence checks' with LIMIT=1 vs ROWNUM<2 and bracketing

## To Do
* Extreme Postgres Dead Row around Idle in Transaction
* Using CTE to get around Postgres hinting limitations (possibly with DBLinks) ?
* Issues with postgres blocking and waiting scripts i.e. https://wiki.postgresql.org/wiki/Lock_Monitoring (latest version of this pages is looking good)
* pgsql functions STABLE or VOLATILE (default) ?

# Going deeper into the Postgres optimizer

Reading Postgres Execution plans isn't too tricky, I've written some simple scripts and made some notes to demo this:

* [Demo-01 Three key execution plan join operations `Nested Loop`, `[Sort] Merge Join` and `Hash Join` Operations](docs/Demo1_NestedLoop_MergeJoin_HashJoin.md)
* [Demo-02 Using `EXPLAIN` with `ANALYZE BUFFERS` to trace sql execution actual performance details](docs/Demo02_with_ANALYZE-BUFFERS.md)
* [Demo-03 postgres `WORK_MEM` parameter challenge and why you might see more Sorts-to-Disk](docs/Demo-03_work_mem_and_Sorts-to-Disk.md)
* [Demo-04 Anti Join (with nested loops)](docs/Demo-04-AntiJoin.md)
* [Demo-05 Materialize SubPlan](docs/Demo05-Materialize-SubPlan.md)
* [Demo-06 Postgres optimizer NOT IN gotcha - still in pg12](docs/Demo-06-Postgres-optimizer-NOT-IN-gotcha.md)
* [Demo-07 Index Scan Backward](docs/Demo07-Index-Scan-Backward.md)

#  Transaction isolation levels

Exploring how different DB Engines implement transaction isolation levels - exploring edge cases!

* [Default READ-COMMITED bahaviour in Postgres - some issues with overlapping transaction](docs/Demo01-Default-READ-COMMITED-issues.md)
* [Default SERIALIZATION in CockroachDB update single row in BLOCKS other SELECT transactions - ouch](docs/Demo02-Default-SERIALIZATION-CRDB-issues.md)
* [Using SERIALIZATION in Postgres transactions start failing - due to read/write dependencies among transactions](docs/Demo03-Using-SERIALIZATION-in-Postgres.md)


# Useful bits and pieces

* [Useful bits and pieces (all)](docs/Useful-Queries.md)
* [pg startup and running time](docs/Useful-Queries.md#pg-startup-and-running-time)
* [WAL Location and Sizing](docs/Useful-Queries.md#wal-location-and-sizing)
* [plpgsql random_json from ryanbooz's FOSDEM 2022 presenation](docs/FOSDEM_2022_random_json.md)
* [psql variables and running in parallel schemas](docs/psql-variables-and-parallel-schemas.md)

# Unindexed foreign keys


* [Demo01 Unindexed_foreign_keys postgres check query](docs/Demo01-Unindexed_foreign_keys-postgres-check-query.md)


# Postrgres FillFactor and HOT (Heap Only Tuple) updates
### Background 

I want to write up some notes on FF and HOT updates
* this is a good start point - nice summary https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/
* but I want to work through some of the details
* also expand on how to monitor and tune this 

### Examples
* [FF and HOT updates - part 01 - simple example with fillfactor 9 - 3 updates and 3 out of 3 are HOT ](docs/FF-and-HOT-updates-part-01.md)
* [FF and HOT updates - part 02 - simple example with fillfactor 100 - 3 updates and only 2 out of 3 are HOT](docs/FF-and-HOT-updates-part-02.md)
* [FF and HOT updates - part 03  -  added `explain (analyze,wal)`](docs/FF-and-HOT-updates-part-03.md)
# Quick setup notes for Mac

Install (or upgrade) via brew
```
brew install postgresql
brew upgrade postgresql
```

start
```
pg_ctl -D /usr/local/var/postgres start
```

setup default user and pgbench databases
```
createdb `whoami`
createdb pgbench
```

install pgbench sample schema
```
pgbench -i -s 15 -d pgbench
``` 
alternatively if using the bench1 user and database:
```
pgbench -i -s 15 -d bench1 -U bench1
```

test connect
```
psql -d pgbench
```

sample query output
```
pgbench=# \d
             List of relations
 Schema |       Name       | Type  | Owner
--------+------------------+-------+--------
 public | pgbench_accounts | table | dpitts
 public | pgbench_branches | table | dpitts
 public | pgbench_history  | table | dpitts
 public | pgbench_tellers  | table | dpitts
(4 rows)
pgbench=# \timing on
Timing is on.
pgbench=# explain select * from pgbench_accounts;
                                QUERY PLAN
---------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..39591.00 rows=1500000 width=97)
(1 row)

Time: 0.355 ms
pgbench=# select count(*) from pgbench_accounts;
  count
---------
 1500000
(1 row)

Time: 106.677 ms
```


