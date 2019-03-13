## Setup - base test_mvcc table with 100000 rows

NB This is can be simplified i.e. simple psql script and drop psycopg2
NB2 This has been simplified i.e. started psql-setup.sql

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # cat mvcc_test_step1.py
import psycopg2,time
try:
    conn = psycopg2.connect("dbname='bench1' user='bench1' host='localhost' password='changeme'")
except:
    print "I am unable to connect to the database"
cur = conn.cursor()
cur.execute("CREATE TABLE test_mvcc (id serial PRIMARY KEY, num integer, data varchar);")
for i in range(1,100000):
  cur.execute("insert into test_mvcc values (%s,%s,%s)",(i,i,"blah blah blah blah blah blah ..................."))
  offset=i-1000
  conn.commit()
cur.close()
conn.close()

[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # time python mvcc_test_step1.py

real    1m13.193s
user    0m2.030s
sys    0m6.370s
```

## Reviewing scripts - 3 sessions - one complex reporting, one batch cleanup job and one DBA running VACUUM 


Simplified version of complex background process/report
```
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # cat session1-SERIALIZABLE-SELECTs-1hour-apart.sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
select count(*) from test_mvcc;
SELECT pg_sleep(3600);
select count(*) from test_mvcc;
```

Simplified version one batch cleanup job

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # cat session2-DELETE-rows.sql
delete from test_mvcc where id < 90000;
```

Typically it would be AUTOVACUUM but to demo the 'nonremovable row' I'm running VACUUM VERBOSE

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # cat session3-VACUUM-hits-non-removal-dead-rows.sql
vacuum verbose test_mvcc;
```




## Results - 89999 dead row versions cannot be removed yet

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # psql -U bench1 -f session1-SERIALIZABLE-SELECTs-1hour-apart.sql &
[1] 12913
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # psql:session1-SERIALIZABLE-SELECTs-1hour-apart.sql:1: WARNING:  SET TRANSACTION can only be used in transaction blocks
SET
 count
-------
 99999
(1 row)


[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # psql -U bench1 -f session2-DELETE-rows.sql
DELETE 89999
[pg10centos7:postgres:~/pg-ora-demo-scripts/mvcc] # psql -U bench1 -f session3-VACUUM-hits-non-removal-dead-rows.sql
psql:session3-VACUUM-hits-non-removal-dead-rows.sql:1: INFO:  vacuuming "public.test_mvcc"
psql:session3-VACUUM-hits-non-removal-dead-rows.sql:1: INFO:  index "test_mvcc_pkey" now contains 99999 row versions in 276 pages
DETAIL:  0 index row versions were removed.
0 index pages have been deleted, 0 are currently reusable.
CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s.
psql:session3-VACUUM-hits-non-removal-dead-rows.sql:1: INFO:  "test_mvcc": found 0 removable, 90055 nonremovable row versions in 1024 out of 1137 pages
DETAIL:  89999 dead row versions cannot be removed yet, oldest xmin: 380382
...
```



