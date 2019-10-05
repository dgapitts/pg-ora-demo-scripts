### setup default user and pgbench databases
```
createdb `whoami`
createdb pgbench
```

### install pgbench sample schema
```
pgbench -i -s 15 -d pgbench
``` 

### test connect via psql
```
psql -d pgbench
```

### sample query output on vanilla pgbench
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
### Add foreign key on pgbench_accounts(bid) to pgbench_branches - pgbench_accounts_fk_bid 
```
pgbench=# \d pgbench_accounts
              Table "public.pgbench_accounts"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 aid      | integer       |           | not null |
 bid      | integer       |           |          |
 abalance | integer       |           |          |
 filler   | character(84) |           |          |
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)

pgbench=# \d pgbench_branches
              Table "public.pgbench_branches"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 bid      | integer       |           | not null |
 bbalance | integer       |           |          |
 filler   | character(88) |           |          |
Indexes:
    "pgbench_branches_pkey" PRIMARY KEY, btree (bid)

pgbench=# alter table pgbench_accounts add constraint foreign key (bid) references pgbench_branches (bid);
2019-10-05 13:42:33.846 CEST [32069] ERROR:  syntax error at or near "foreign" at character 45
2019-10-05 13:42:33.846 CEST [32069] STATEMENT:  alter table pgbench_accounts add constraint foreign key (bid) references pgbench_branches (bid);
ERROR:  syntax error at or near "foreign"
LINE 1: alter table pgbench_accounts add constraint foreign key (bid...
                                                    ^
pgbench=# alter table pgbench_accounts add constraint pgbench_accounts_fk_bid foreign key (bid) references pgbench_branches (bid);
ALTER TABLE
pgbench=# \d pgbench_accounts
              Table "public.pgbench_accounts"
  Column  |     Type      | Collation | Nullable | Default
----------+---------------+-----------+----------+---------
 aid      | integer       |           | not null |
 bid      | integer       |           |          |
 abalance | integer       |           |          |
 filler   | character(84) |           |          |
Indexes:
    "pgbench_accounts_pkey" PRIMARY KEY, btree (aid)
Foreign-key constraints:
    "pgbench_accounts_fk_bid" FOREIGN KEY (bid) REFERENCES pgbench_branches(bid)
```