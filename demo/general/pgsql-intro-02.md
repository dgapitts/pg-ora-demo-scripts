## Still a very simple demo but using a cursor to seed our for-loop

The generate_series() function is very useful

```
~/projects/pg-ora-demo-scripts/demo/general $ psql
psql (13.3)
Type "help" for help.

dave=# select generate_series(1, 6);
 generate_series 
-----------------
               1
               2
               3
               4
               5
               6
(6 rows)

dave=# \q
```

using this to seed out for-loop 

```
~/projects/pg-ora-demo-scripts/demo/general $ cat pgsql-loop-002.sql 
-- https://www.postgresqltutorial.com/plpgsql-for-loop/
do $$
declare
    counter record;
begin
   for counter in select generate_series(1, 6)
   loop
	raise notice 'counter: %', counter;
   end loop;
end; $$


```
gives
```
~/projects/pg-ora-demo-scripts/demo/general $ vim pgsql-loop-002.sql 
~/projects/pg-ora-demo-scripts/demo/general $ psql -f pgsql-loop-002.sql 
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (1)
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (2)
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (3)
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (4)
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (5)
psql:pgsql-loop-002.sql:11: NOTICE:  counter: (6)
DO
```


