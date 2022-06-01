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


