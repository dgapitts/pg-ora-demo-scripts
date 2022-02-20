## Working with psql variables and running in parallel schemas

* I want to run the same script in parallel schemas
* I can achieve this  psql variables (https://stackoverflow.com/questions/36959/how-do-you-use-script-variables-in-psql)
* I also hit a gotcha with "create schema permission denied for database"



```
[pg13centos7:vagrant:~] # cat vSchema_test.sql
create schema :vSchema;
set search_path=:vSchema;
show search_path;
```

and running this:
```
pg13centos7:vagrant:~] # psql -f  -v vSchema="test_schema"
psql:vSchema_test.sql:1: ERROR:  permission denied for database vagrant
SET
 search_path
-------------
 test_schema
(1 row)
```

I reviewed a couple of post

* https://dba.stackexchange.com/questions/121781/user-cannot-create-schema-in-postgressql-database 
* https://stackoverflow.com/questions/59654544/postgresql-create-a-schema-fail-to-grant-privileges

I'm not sure if this is what I was meant to do 

```
GRANT CREATE ON SCHEMA public TO vagrant;
```

but in the end went with granting SUPERUSER priveleges to my demo/vagrant user (will review this again at some stage)

```
postgres=# ALTER ROLE vagrant WITH SUPERUSER;
ALTER ROLE
```


and now this works

```
[pg13centos7:vagrant:~] # psql -f vSchema_test.sql -v vSchema="test_schema"
CREATE SCHEMA
SET
 search_path
-------------
 test_schema
(1 row)
```

