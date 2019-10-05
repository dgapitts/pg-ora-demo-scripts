### setup default user and pgbench databases
```
~ $ time createdb pgbench

real	0m1.178s
user	0m0.011s
sys	0m0.010s

```

### install pgbench sample schema
```
~ $ time pgbench -i -s 3 -d pgbench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data...
100000 of 300000 tuples (33%) done (elapsed 0.33 s, remaining 0.66 s)
200000 of 300000 tuples (66%) done (elapsed 0.90 s, remaining 0.45 s)
300000 of 300000 tuples (100%) done (elapsed 1.34 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.

real	0m2.110s
user	0m0.174s
sys	0m0.029s
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
-------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..7919.00 rows=300000 width=97)
(1 row)

Time: 3.165 ms
pgbench=# select count(*) from pgbench_accounts;
 count
--------
 300000
(1 row)

Time: 112.382 ms
pgbench=# select count(*) from pgbench_accounts;
 count
--------
 300000
(1 row)

Time: 29.915 ms
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

### Setting account balance based off random() function

```
pgbench=# select trunc(random()*(10000*random())^2);
  trunc
----------
 14692546
(1 row)

pgbench=# \timing on
Timing is on.
pgbench=# update pgbench_accounts set abalance = trunc(random()*(10000*random())^2);
UPDATE 300000
Time: 4894.723 ms (00:04.895)
pgbench=# select * from pgbench_accounts limit 5;
 aid | bid | abalance |                                        filler
-----+-----+----------+--------------------------------------------------------------------------------------
   1 |   1 |    32375 |
   2 |   1 |     3324 |
   3 |   1 |  3482503 |
   4 |   1 |  1317682 |
   5 |   1 | 42034757 |
(5 rows)

Time: 0.409 ms
```

### Calculate sum(), avg(), stddev () for account balance
```
pgbench=# select sum(abalance),avg(abalance),stddev(abalance),bid from pgbench_accounts group by bid;
      sum      |          avg          |    stddev     | bid
---------------+-----------------------+---------------+-----
 1664430319002 | 16644303.190020000000 | 19717983.4829 |   1
 1665812580888 | 16658125.808880000000 | 19729594.0730 |   2
 1658596311769 | 16585963.117690000000 | 19684150.3421 |   3
(3 rows)

Time: 132.219 ms
```



### Add account names column (aname) and then populate randomly from {Ava,Alex,Aiden,Abigail}

```
pgbench=# select ('[0:3]={Ava,Alex,Aiden,Abigail}'::text[])[floor(random()*4)];
 text
------
 Alex
(1 row)

Time: 1.260 ms
pgbench=# alter table pgbench_accounts add aname character(20);
ALTER TABLE
Time: 112.133 ms
pgbench=# update pgbench_accounts set aname = ('[0:3]={Ava,Alex,Aiden,Abigail}'::text[])[floor(random()*4)];
UPDATE 300000
Time: 5377.962 ms (00:05.378)
pgbench=# select aname, count(*) from pgbench_accounts group by aname;
        aname         | count
----------------------+-------
 Abigail              | 74508
 Aiden                | 74972
 Alex                 | 75376
 Ava                  | 75144
(4 rows)

Time: 138.327 ms
```


### Add branch manager names column (mname) and then populate randomly from {Bella,Brittany,Brenda,Belen}

```
pgbench=# select ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
 text
------
 Belen
(1 row)

Time: 1.260 ms
pgbench=# alter table pgbench_branches add mname character(20);
ALTER TABLE
Time: 3.988 ms
pgbench=# update pgbench_branches set mname = ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
UPDATE 3
Time: 74.112 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brittany
(3 rows)

Time: 0.294 ms
pgbench=# update pgbench_branches set mname ='Brenda' where bid=3;
UPDATE 1
Time: 1.721 ms
pgbench=# select * from pgbench_branches;
 bid | bbalance | filler |        mname
-----+----------+--------+----------------------
   1 |        0 |        | Belen
   2 |        0 |        | Brittany
   3 |        0 |        | Brenda
(3 rows)

Time: 0.376 ms
```





