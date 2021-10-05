## Summary

This will not be a huge surprise for many, but still some developers are surprised by this sort of transactionally / MVCC behaviour: 
* Loop with select statement - 6 executions each at 2 sec intervals - but timestamp set at transaction
* Regular select statement - 6 executions each at 2 sec intervals - now() varies as expected

This is only a fairly basic example, [MVCC (Multiple Version Concurrency)](https://en.wikipedia.org/wiki/Multiversion_concurrency_control) gets more complex...

## Loop with select statement - 6 executions each at 2 sec intervals - but timestamp set at transaction

```
~/projects/pg-ora-demo-scripts/demo/general $ cat pgsql-loop-003.sql
-- https://www.postgresqltutorial.com/plpgsql-for-loop/
do $$
declare
    counter record;
    current_time record;
begin
   for counter in select generate_series(1, 6)
   loop
      for current_time in select now(),pg_sleep(2)
      loop 
         raise notice '%', current_time;
      end loop;
   end loop;
end; $$
```
and note the time now() returns the same time (i.e. trasaction start time)
```
~/projects/pg-ora-demo-scripts/demo/general $ date;time psql -f pgsql-loop-003.sql;date
Mon Oct  4 22:07:10 BST 2021
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
psql:pgsql-loop-003.sql:15: NOTICE:  23:07:10.220138+02
DO

real	0m12.703s
user	0m0.011s
sys	0m0.018s
Mon Oct  4 22:07:22 BST 2021
```

## Regular select statement - 6 executions each at 2 sec intervals - now() varies as expected

Very very simple script

```
~/projects/pg-ora-demo-scripts/demo/general $ cat simple_pg_sleep_demo.sql
select now(),pg_sleep(2);
select now(),pg_sleep(2);
select now(),pg_sleep(2);
select now(),pg_sleep(2);
select now(),pg_sleep(2);
select now(),pg_sleep(2);
```

and no surpises running this

```
~/projects/pg-ora-demo-scripts/demo/general $ date;time psql -f simple_pg_sleep_demo.sql;date
Mon Oct  4 22:10:25 BST 2021
              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:26.055771+02 | 
(1 row)

              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:28.128518+02 | 
(1 row)

              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:30.203228+02 | 
(1 row)

              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:32.308863+02 | 
(1 row)

              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:34.375545+02 | 
(1 row)

              now              | pg_sleep 
-------------------------------+----------
 2021-10-04 23:10:36.442342+02 | 
(1 row)


real	0m12.500s
user	0m0.009s
sys	0m0.010s
Mon Oct  4 22:10:38 BST 2021
```
