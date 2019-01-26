== How to run ==

I started with the extremely simple python script
```
~/projects/pg-ora-demo-scripts/memtest $ cat gen_sql.py
for i in range(10001):
    print "create table tab"+str(i)+" (pk integer primary key, col1 varchar(30)); "
```

and then can run via
```
~/projects/pg-ora-demo-scripts/memtest $ python gen_sql.py > create_table.sql
~/projects/pg-ora-demo-scripts/memtest $ head -3 create_table.sql
create table tab0 (pk integer primary key, col1 varchar(30));
create table tab1 (pk integer primary key, col1 varchar(30));
create table tab2 (pk integer primary key, col1 varchar(30));
~/projects/pg-ora-demo-scripts/memtest $ tail -3 create_table.sql
create table tab9998 (pk integer primary key, col1 varchar(30));
create table tab9999 (pk integer primary key, col1 varchar(30));
create table tab10000 (pk integer primary key, col1 varchar(30));
~/projects/pg-ora-demo-scripts/memtest $
```

== Background on postgres data_directory and pg_class.relfilenode==
After running:

```
postgres=# create table tab1 (pk integer primary key, col1 varchar(30));
CREATE TABLE

```

where is my table stored at the OS level?

Well the base directory is data_directory:

```
postgres=# show data_directory;
     data_directory
------------------------
 /var/lib/pgsql/10/data
(1 row)
```										

lets dump a 'snapshot of the filesystem' (via tree) under data_directory:

```
[pg10centos7:postgres:~/10/data] # tree > /tmp/temp1
```

and now create a 2nd table:
```
postgres=# create table tab2 (pk integer primary key, col1 varchar(30));
CREATE TABLE
```

and now compare before & after 'snapshot of the filesystem':

```
[pg10centos7:postgres:~/10/data] # tree > /tmp/temp2
[pg10centos7:postgres:~/10/data] # diff /tmp/temp1 /tmp/temp2
648a649,650
> │       ├── 16402
993c995
< 26 directories, 964 files
---
> 26 directories, 966 files
```

so now we can 

```
less /tmp/temp2
.
├── base
│   ├── 1
│   │   ├── 112
│   │   ├── 113
│   │   ├── 1247
...

   └── 12953
│       ├── 112
│       ├── 113
...
│       ├── 16402
```

and in pg_class

```
postgres=# SELECT relname, relfilenode FROM pg_class WHERE relname = 'tab1';
 relname | relfilenode
---------+-------------
 tab2    |       16402
(1 row)
````


