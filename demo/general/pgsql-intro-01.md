
Starting with a very simple demo for loop borrow from [postgresqltutorial.com/plpgsql-for-loop](https://www.postgresqltutorial.com/plpgsql-for-loop/)
```
~/projects/pg-ora-demo-scripts/demo/general $ cat pgsql-loop-001.sql
do $$
begin
   for counter in 1..5 loop
	raise notice 'counter: %', counter;
   end loop;
end; $$
```
and running this simple demo:
```
~/projects/pg-ora-demo-scripts/demo/general $ psql -f pgsql-loop-001.sql 
psql:pgsql-loop-001.sql:6: NOTICE:  counter: 1
psql:pgsql-loop-001.sql:6: NOTICE:  counter: 2
psql:pgsql-loop-001.sql:6: NOTICE:  counter: 3
psql:pgsql-loop-001.sql:6: NOTICE:  counter: 4
psql:pgsql-loop-001.sql:6: NOTICE:  counter: 5
DO
```
