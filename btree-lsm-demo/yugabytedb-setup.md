# Yugabytedb setup with big insert tests - some interesting stats

```
docker pull yugabytedb/yugabyte:2.19.3.0-b140
```
then
```
docker run -d --name yugabyte -p7001:7000 -p9000:9000 -p15433:15433 -p5433:5433 -p9042:9042 \
 yugabytedb/yugabyte:2.19.3.0-b140 bin/yugabyted start \
 --background=false
 ```

 note 


 then running 

 ```
 davidpitts@Davids-MacBook-Pro ~ % docker ps
CONTAINER ID   IMAGE                                           COMMAND                  CREATED          STATUS                 PORTS                                                                                                                                                                                               NAMES
205f8695eed6   yugabytedb/yugabyte:2.19.3.0-b140               "/sbin/tini -- bin/y…"   24 seconds ago   Up 22 seconds          6379/tcp, 7100/tcp, 0.0.0.0:5433->5433/tcp, 0.0.0.0:9000->9000/tcp, 7200/tcp, 9100/tcp, 10100/tcp, 11000/tcp, 0.0.0.0:9042->9042/tcp, 0.0.0.0:15433->15433/tcp, 12000/tcp, 0.0.0.0:7001->7000/tcp   yugabyte
9d4b19818b46   cockroach-docker-postgresql                     "/usr/bin/tail -f /d…"   9 days ago       Up 9 days              5432/tcp                                                                                                                                                                                            postgresql
3d22d987d48c   cockroach-docker-lb                             "docker-entrypoint.s…"   9 days ago       Up 9 days              0.0.0.0:8080-8081->8080-8081/tcp, 0.0.0.0:26000->26000/tcp, 26257/tcp                                                                                                                               lb
f5b7c1397e97   cockroachdb/cockroach-unstable:v23.2.0-beta.1   "/cockroach/cockroac…"   9 days ago       Up 9 days              8080/tcp, 26257/tcp                                                                                                                                                                                 roach-1
bd52ac4978c6   cockroachdb/cockroach-unstable:v23.2.0-beta.1   "/cockroach/cockroac…"   9 days ago       Up 9 days              8080/tcp, 26257/tcp                                                                                                                                                                                 roach-0
b311a75137c0   cockroachdb/cockroach-unstable:v23.2.0-beta.1   "/usr/bin/tail -f /d…"   9 days ago       Up 9 days              8080/tcp, 26257/tcp                                                                                                                                                                                 client
46e06517cbed   cockroachdb/cockroach-unstable:v23.2.0-beta.1   "/cockroach/cockroac…"   9 days ago       Up 9 days              8080/tcp, 26257/tcp                                                                                                                                                                                 roach-2
967312bf81fb   jupyter/base-notebook                           "tini -g -- start-no…"   13 days ago      Up 13 days (healthy)   0.0.0.0:10000->8888/tcp                                                                                                                                                                             awesome_lamarr
6f5a3bbda7c2   vidardb/postgresql:rocksdb-6.2.4_demo03_bkp     "docker-entrypoint.s…"   13 days ago      Up 13 days             5432/tcp                                                                                                                                                                                            pg_rocksdb3
51950d7f2812   vidardb/postgresql:rocksdb-6.2.4_demo04         "docker-entrypoint.s…"   2 weeks ago      Up 2 weeks             5432/tcp                                                                                                                                                                                            pg_rocksdb_test2
a28dc07b9b4f   vidardb/postgresql:rocksdb-6.2.4_demo03         "docker-entrypoint.s…"   2 weeks ago      Up 2 weeks    
```


Nice status tool
```
davidpitts@Davids-MacBook-Pro ~ % docker exec -it yugabyte yugabyted status

+----------------------------------------------------------------------------------------------------------+
|                                                yugabyted                                                 |
+----------------------------------------------------------------------------------------------------------+
| Status              : Running.                                                                           |
| Replication Factor  : 1                                                                                  |
| YugabyteDB UI       : http://172.17.0.6:15433                                                            |
| JDBC                : jdbc:postgresql://172.17.0.6:5433/yugabyte?user=yugabyte&password=yugabyte                  |
| YSQL                : bin/ysqlsh -h 172.17.0.6  -U yugabyte -d yugabyte                                  |
| YCQL                : bin/ycqlsh 172.17.0.6 9042 -u cassandra                                            |
| Data Dir            : /root/var/data                                                                     |
| Log Dir             : /root/var/logs                                                                     |
| Universe UUID       : 409a08dd-cc9c-4282-b525-c34a494e9565                                               |
+----------------------------------------------------------------------------------------------------------+
```


Connect (bash shell) to the docker install
* No pgbench install (runing RHEL8 but not seem which version of postgresql??-contrib to install
* Ran some simple large insert tests 
```
insert into big_table(id) SELECT generate_series(1,100);
explain select filler from big_table where id = 8;
analyze big_table;

insert into big_table(id) SELECT generate_series(1,1000);
analyze big_table;
explain select filler from big_table where id = 80;

insert into big_table(id) SELECT generate_series(1,10000);
analyze big_table;
explain select filler from big_table where id = 800;

insert into big_table(id) SELECT generate_series(1,100000);
analyze big_table;
explain analyze select filler from big_table where id = 80000;

insert into big_table(id) SELECT generate_series(1,200000);
analyze big_table;
explain analyze select filler from big_table where id = 80000;


insert into big_table(id) SELECT generate_series(1,400000);
analyze big_table;
explain analyze select filler from big_table where id = 80000;
```
* Some interesting results - optimizer stats seem wonky
```
```

details

```
davidpitts@Davids-MacBook-Pro ~ % docker exec -it yugabyte bash
[root@205f8695eed6 yugabyte]# cd postgres/bin/
clusterdb            ecpg                 pg_config            pg_recvlogical       pg_test_fsync        postgres             ysql_bench
createdb             initdb               pg_controldata       pg_resetwal          pg_test_timing       postmaster           ysql_dump
createuser           oid2name             pg_ctl               pg_restore           pg_upgrade           reindexdb            ysql_dumpall
dropdb               pg_archivecleanup    pg_isready           pg_rewind            pg_verify_checksums  vacuumdb             ysqlsh
dropuser             pg_basebackup        pg_receivewal        pg_standby           pg_waldump           vacuumlo
[root@205f8695eed6 yugabyte]# cd postgres/bin/
[root@205f8695eed6 bin]# /home/yugabyte/bin/ysqlsh --echo-queries --host $(hostname)
ysqlsh (11.2-YB-2.19.3.0-b0)
Type "help" for help.

yugabyte=# \l
                                   List of databases
      Name       |  Owner   | Encoding | Collate |    Ctype    |   Access privileges
-----------------+----------+----------+---------+-------------+-----------------------
 postgres        | postgres | UTF8     | C       | en_US.UTF-8 |
 system_platform | postgres | UTF8     | C       | en_US.UTF-8 |
 template0       | postgres | UTF8     | C       | en_US.UTF-8 | =c/postgres          +
                 |          |          |         |             | postgres=CTc/postgres
 template1       | postgres | UTF8     | C       | en_US.UTF-8 | =c/postgres          +
                 |          |          |         |             | postgres=CTc/postgres
 yugabyte        | postgres | UTF8     | C       | en_US.UTF-8 |
(5 rows)

yugabyte=# create database bench1;
create database bench1;
CREATE DATABASE
yugabyte=# \q
[root@205f8695eed6 bin]# cat /etc/
Display all 129 possibilities? (y or n)
[root@205f8695eed6 bin]# cat /etc/re
redhat-release  resolv.conf
[root@205f8695eed6 bin]# cat /etc/re
redhat-release  resolv.conf
[root@205f8695eed6 bin]# cat /etc/redhat-release
AlmaLinux release 8.8 (Sapphire Caracal)
[root@205f8695eed6 bin]# psql
bash: psql: command not found
[root@205f8695eed6 bin]# /home/yugabyte/bin/ysqlsh --echo-queries --host $(hostname)
ysqlsh (11.2-YB-2.19.3.0-b0)
Type "help" for help.

yugabyte=# \c bench1
You are now connected to database "bench1" as user "yugabyte".
bench1=# create table t1(f1 int);
create table t1(f1 int);
CREATE TABLE
bench1=# create table big_table(id int,filler varchar(100) default '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789');
create table big_table(id int,filler varchar(100) default '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789');
CREATE TABLE
bench1=# \timing on
Timing is on.
bench1=# insert into big_table(id) SELECT generate_series(1,100);
insert into big_table(id) SELECT generate_series(1,100);
INSERT 0 100
Time: 158.253 ms
bench1=# \d t1
                 Table "public.t1"
 Column |  Type   | Collation | Nullable | Default
--------+---------+-----------+----------+---------
 f1     | integer |           |          |

bench1=# \d big_table
                                                                              Table "public.big_table"
 Column |          Type          | Collation | Nullable |                                                          Default

--------+------------------------+-----------+----------+--------------------------------------------------------------------------------------------------
-------------------------
 id     | integer                |           |          |
 filler | character varying(100) |           |          | '012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
6789'::character varying

bench1=# explain select filler from big_table where id = 8;
explain select filler from big_table where id = 8;
                           QUERY PLAN
----------------------------------------------------------------
 Seq Scan on big_table  (cost=0.00..102.50 rows=1000 width=218)
   Remote Filter: (id = 8)
(2 rows)

Time: 33.044 ms
bench1=# insert into big_table(id) SELECT generate_series(1,100);
insert into big_table(id) SELECT generate_series(1,100);
INSERT 0 100
Time: 108.466 ms
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 140.269 ms
bench1=# insert into big_table(id) SELECT generate_series(1,100);
insert into big_table(id) SELECT generate_series(1,100);
INSERT 0 100
Time: 82.791 ms
bench1=# explain select filler from big_table where id = 8;
explain select filler from big_table where id = 8;
                          QUERY PLAN
--------------------------------------------------------------
 Seq Scan on big_table  (cost=0.00..20.50 rows=200 width=218)
   Remote Filter: (id = 8)
(2 rows)

Time: 20.813 ms
bench1=# create index on big_table_id on big_table(id);
create index on big_table_id on big_table(id);
ERROR:  syntax error at or near "on"
LINE 1: create index on big_table_id on big_table(id);
                                     ^
Time: 54.529 ms
bench1=# create index big_table_id on big_table(id);
create index big_table_id on big_table(id);
CREATE INDEX
Time: 3335.487 ms (00:03.335)
bench1=# insert into big_table(id) SELECT generate_series(1,10000);
insert into big_table(id) SELECT generate_series(1,10000);
INSERT 0 10000
Time: 659.436 ms
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 227.590 ms
bench1=# explain select filler from big_table where id = 800;
explain select filler from big_table where id = 800;
                                    QUERY PLAN
-----------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..16.62 rows=103 width=218)
   Index Cond: (id = 800)
(2 rows)

Time: 23.816 ms
bench1=#
bench1=# insert into big_table(id) SELECT generate_series(1,100000);
insert into big_table(id) SELECT generate_series(1,100000);
INSERT 0 100000
Time: 5223.912 ms (00:05.224)
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 1575.350 ms (00:01.575)
bench1=# explain select filler from big_table where id = 80000;
explain select filler from big_table where id = 80000;
                                     QUERY PLAN
-------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..139.12 rows=1103 width=218)
   Index Cond: (id = 80000)
(2 rows)

Time: 27.943 ms
bench1=# explain analyze select filler from big_table where id = 80000;
explain analyze select filler from big_table where id = 80000;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..139.12 rows=1103 width=218) (actual time=30.216..30.422 rows=1 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 4.234 ms
 Execution Time: 32.256 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 56.993 ms
bench1=# insert into big_table(id) SELECT generate_series(1,1000000);
insert into big_table(id) SELECT generate_series(1,1000000);
INSERT 0 1000000
Time: 62023.988 ms (01:02.024)
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 9992.229 ms (00:09.992)
bench1=# explain analyze select filler from big_table where id = 80000;
explain analyze select filler from big_table where id = 80000;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..1364.12 rows=11103 width=218) (actual time=9.031..9.064 rows=2 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 20.884 ms
 Execution Time: 9.477 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 80.075 ms
bench1=# insert into big_table(id) SELECT generate_series(1,2000000);
insert into big_table(id) SELECT generate_series(1,2000000);
^CCancel request sent
ERROR:  canceling statement due to user request
Time: 26462.895 ms (00:26.463)
bench1=#
bench1=#
bench1=# insert into big_table(id) SELECT generate_series(1,200000);
insert into big_table(id) SELECT generate_series(1,200000);
INSERT 0 200000
Time: 15487.505 ms (00:15.488)
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 6003.193 ms (00:06.003)
bench1=# explain analyze select filler from big_table where id = 80000;
explain analyze select filler from big_table where id = 80000;
                                                            QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..1609.12 rows=13103 width=218) (actual time=19.042..19.101 rows=3 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 17.324 ms
 Execution Time: 20.832 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 129.549 ms
bench1=# explain (analyze,buffers) select filler from big_table where id = 80000;
explain (analyze,buffers) select filler from big_table where id = 80000;
                                                            QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..1609.12 rows=13103 width=218) (actual time=16.940..17.116 rows=3 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 4.123 ms
 Execution Time: 18.230 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 38.244 ms
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 3987.802 ms (00:03.988)
bench1=# explain (analyze,buffers) select filler from big_table where id = 80000;
explain (analyze,buffers) select filler from big_table where id = 80000;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..1609.12 rows=13103 width=218) (actual time=4.147..4.204 rows=3 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 0.935 ms
 Execution Time: 4.596 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 7.661 ms
bench1=# insert into big_table(id) SELECT generate_series(1,400000);
insert into big_table(id) SELECT generate_series(1,400000);
INSERT 0 400000
Time: 29058.378 ms (00:29.058)
bench1=# analyze big_table;
analyze big_table;
WARNING:  'analyze' is a beta feature!
LINE 1: analyze big_table;
        ^
HINT:  Set 'ysql_beta_features' yb-tserver gflag to true to suppress the warning for all beta features.
ANALYZE
Time: 5743.785 ms (00:05.744)
bench1=# explain (analyze,buffers) select filler from big_table where id = 80000;
explain (analyze,buffers) select filler from big_table where id = 80000;
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using big_table_id on big_table  (cost=0.00..2099.12 rows=17103 width=218) (actual time=8.996..9.050 rows=4 loops=1)
   Index Cond: (id = 80000)
 Planning Time: 7.983 ms
 Execution Time: 10.065 ms
 Peak Memory Usage: 8 kB
(5 rows)

Time: 94.302 ms
```