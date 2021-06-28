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

* [Demo-01 of the three key execution plan join operations Nested Loop, [Sort] Merge Join and Hash Join Operations](docs/Demo1_NestedLoop_MergeJoin_HashJoin.md)
* [Demo-02 explan with ANALYZE-BUFFERS](docs/Demo02_with_ANALYZE-BUFFERS.md)
* [Demo-03 work_mem and Sorts-to-Disk](docs/Demo-03_work_mem_and_Sorts-to-Disk.md)


s
## Quick setup notes for Mac

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


