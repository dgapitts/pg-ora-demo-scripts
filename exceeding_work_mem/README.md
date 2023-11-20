# Exceeding work mem - individual (private) process memory usage can get out-of-control

## Background

Referring the `work_mem` it is a limit on the individual (private) process memory usage when running query:
 
> Sets the base maximum amount of memory to be used by a query operation (such as a sort or hash table) before writing to temporary disk files. If this value is specified without units, it is taken as kilobytes. The default value is four megabytes (4MB). 


Although there is a caveat around parallel process  i.e. if work_mem is say 50MB and we have 8 parallel processes then an individual could get to 8*50=400MB

> Note that for a complex query, several sort or hash operations might be running in parallel; each operation will generally be allowed to use as much memory as this value specifies before it starts to write data into temporary files.


**However** the problem is that all these limits appear to only apply during the "execution phase" and there appear to be missing safety checks and control mechanisms during the "planning phase"


## Blowing memory usage during "planning phase"


It is not uncommon for SQL statements to be dynamically generated. Naturally with any program, there are ocassionally edge cases and bugs which can be very hard to debug...

I'm simulated this genre of problem with a simple pyhton script and a pretty crazy looking query, the keys however 
* it runs of a generic pgbench schema
* it is easy to understand 
* as the number of table UNION operations increases - the planning time increases rapidlly and exponentially where as the execution time is moderate and grows linearly
* at a certain point, we see extreme RAM and SWAP usage


## Setup


Starting with a new postgres cluster and install pgbench into my default (dave) user database
```
pg_ctl init -D /usr/local/var/postgres
createdb dave
pgbench -i -d dave
```
for example running this on my home laptop:
```
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ pg_ctl init -D /usr/local/var/postgres
The files belonging to this database system will be owned by user "dave".
This user must also own the server process.

The database cluster will be initialized with locales
  COLLATE:  C
  CTYPE:    UTF-8
  MESSAGES: C
  MONETARY: C
  NUMERIC:  C
  TIME:     C
The default database encoding has accordingly been set to "UTF8".
initdb: could not find suitable text search configuration for locale "UTF-8"
The default text search configuration will be set to "simple".

Data page checksums are disabled.

creating directory /usr/local/var/postgres ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Europe/Madrid
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    '/usr/local/Cellar/postgresql@14/14.4/bin/pg_ctl' -D /usr/local/var/postgres -l logfile start

(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ pg_status
rm  *_times_gen_crazy_big_sql_statement.log
pg_ctl: server is running (PID: 29615)
/usr/local/Cellar/postgresql@14/14.4/bin/postgres "-D" "/usr/local/var/postgres"
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ bash crazy_big_sql_statement_scale100.sh
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  database "dave" does not exist
 100
 100
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ pg_status
pg_ctl: server is running (PID: 29615)
/usr/local/Cellar/postgresql@14/14.4/bin/postgres "-D" "/usr/local/var/postgres"
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ createdb dave
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ pgbench -i -d dave
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.83 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.35 s (drop tables 0.00 s, create tables 0.12 s, client-side generate 0.95 s, vacuum 0.19 s, primary keys 0.09 s).
```


### Running gen_crazy_big_sql_statement.py and logging results over 100, 200, 300, ... 2000 UNION statements

To get started we only need 

* gen_crazy_big_sql_statement.py (which is called by crazy_big_sql_statement_scale100.sh)

```
import sys

#limit=10
limit=int(sys.argv[1])

"""
This is our starting point

explain (analyze,buffers)
select alias_pgbench_accounts_1.abalance+alias_pgbench_accounts_2.abalance
from
(select abalance from pgbench_accounts where aid = 1) alias_pgbench_accounts_1,
(select abalance from pgbench_accounts where aid = 2) alias_pgbench_accounts_2;

psql >

                                                                           QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.58..16.63 rows=1 width=4) (actual time=0.020..0.021 rows=1 loops=1)
   Buffers: shared hit=6
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.014..0.014 rows=1 loops=1)
         Index Cond: (aid = 1)
         Buffers: shared hit=3
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=0.005..0.005 rows=1 loops=1)
         Index Cond: (aid = 2)
         Buffers: shared hit=3
 Planning Time: 0.140 ms
 Execution Time: 0.035 ms
(10 rows)
"""

crazy_big_sql_statement="explain (analyze,buffers) select alias_pgbench_accounts_1.abalance+alias_pgbench_accounts_2.abalance"
crazy_big_sql_statement+="\n"
crazy_big_sql_statement+="from"
crazy_big_sql_statement+="\n"
crazy_big_sql_statement+="(select abalance from pgbench_accounts where aid = 1) alias_pgbench_accounts_1"
crazy_big_sql_statement+="\n"


for i in range(2,limit):
    crazy_big_sql_statement+=",(select abalance from pgbench_accounts where aid = "+str(i)+") alias_pgbench_accounts_"+str(i)
    crazy_big_sql_statement+="\n"


crazy_big_sql_statement+=",(select abalance from pgbench_accounts where aid = "+str(limit)+") alias_pgbench_accounts_"+str(limit)+";"
print(crazy_big_sql_statement)
```
* crazy_big_sql_statement_scale100.sh (the starting 100 UNION test case)
```
python3 gen_crazy_big_sql_statement.py 100 > test_100.sql
#cat test_100.sql
psql -f test_100.sql >  test_100.log
#tail -10 test_100.log
echo `grep 'Execution Time:' test_100.log | awk '{print $3}'` " 100" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_100.log | awk '{print $3}'` " 100" | tee -a plan_times_gen_crazy_big_sql_statement.log
```
* wrapper_crazy_big_sql_statement.sh 
```
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ cat wrapper_crazy_big_sql_statement.sh
rm  *_times_gen_crazy_big_sql_statement.log

for i in {2..20}
do
  size=$((i))00;sed "s/100/$size/g" ./crazy_big_sql_statement_scale100.sh | tee ./crazy_big_sql_statement_scale$size.sh
  bash ./crazy_big_sql_statement_scale$size.sh
done

echo "final results";head -100 *_times_gen_crazy_big_sql_statement.log

```

And the only script which needs to be run is `wrapper_crazy_big_sql_statement.sh`

```
(base) ~/projects/pg-ora-demo-scripts/exceeding_work_mem $ bash wrapper_crazy_big_sql_statement.sh
python3 gen_crazy_big_sql_statement.py 200 > test_200.sql
#cat test_200.sql
psql -f test_200.sql >  test_200.log
#tail -10 test_200.log
echo `grep 'Execution Time:' test_200.log | awk '{print $3}'` " 200" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_200.log | awk '{print $3}'` " 200" | tee -a plan_times_gen_crazy_big_sql_statement.log

23.708  200
846.179  200
python3 gen_crazy_big_sql_statement.py 300 > test_300.sql
#cat test_300.sql
psql -f test_300.sql >  test_300.log
#tail -10 test_300.log
echo `grep 'Execution Time:' test_300.log | awk '{print $3}'` " 300" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_300.log | awk '{print $3}'` " 300" | tee -a plan_times_gen_crazy_big_sql_statement.log

11.641  300
2063.668  300
python3 gen_crazy_big_sql_statement.py 400 > test_400.sql
#cat test_400.sql
psql -f test_400.sql >  test_400.log
#tail -10 test_400.log
echo `grep 'Execution Time:' test_400.log | awk '{print $3}'` " 400" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_400.log | awk '{print $3}'` " 400" | tee -a plan_times_gen_crazy_big_sql_statement.log
...
```



## Results over 100, 200, 300, ... 2000 UNION statements

```
==> exec_times_gen_crazy_big_sql_statement.log <==
23.708  200
11.641  300
25.867  400
25.787  500
26.888  600
30.647  700
39.992  800
41.685  900
51.755  1000
69.537  1100
86.475  1200
96.521  1300
208.983  1400
147.970  1500
138.689  1600
200.091  1700
157.139  1800
255.389  1900
163.383  2000
```


```
==> plan_times_gen_crazy_big_sql_statement.log <==
846.179  200
2063.668  300
3619.553  400
6556.015  500
9192.979  600
13578.243  700
19641.523  800
27358.637  900
33749.735  1000
44670.798  1100
55666.864  1200
71213.366  1300
96415.790  1400
107869.397  1500
128097.082  1600
159554.728  1700
256793.288  1800
197244.957  1900
287216.804  2000
```
