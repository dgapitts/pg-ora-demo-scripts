## Overview of test setup and results

Test setup
* test one  - pgbench 30 concurrent test threads and pgbouncer pool with 10 connections 
* test one  - pgbench 30 concurrent test threads and pgbouncer pool with 20 connections

Test results
* test one  - load averages around 12.13 and 11574 postgres file handles - peak query rate 1003 queries/s
* test one  - load averages around 21.8 and 22841 postgres file handles - peak query rate 418 queries/s

## Connclusions 

Om my very small environment with only 500Mb of RAM 

```
[pg10centos7:postgres:~/pg-ora-demo-scripts] # free -m
              total        used        free      shared  buff/cache   available
Mem:            487          52         311          23         123         371
Swap:          2047         184        1863
```

and two CPUs

```
[pg10centos7:postgres:~/pg-ora-demo-scripts] # grep 'processor\|model name' /proc/cpuinfo
processor	: 0
model name	: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
processor	: 1
model name	: Intel(R) Core(TM) i7-4850HQ CPU @ 2.30GHz
```

a connection pool of 10 gives significantly better throughput than 20 connections.    


## Tech Details - test one  - pgbench 30 concurrent test threads and pgbouncer pool with 10 connections 
```
pgbench -h localhost -p 6432 -d pgbbench -U bench1 -c 30 -j 30 -T 300 -f custom_bench_nowait.sql
```

connection pool size
```
[pg10centos7:root:/var/log/pgbouncer] # grep default_pool_size /etc/pgbouncer/pgbouncer.ini
default_pool_size = 10
```

monitoring script

```
[pg10centos7:root:/var/log/pgbouncer] # for i in {1..1000};do uptime;lsof | grep postgres | wc -l;ps -ef|grep bench;sleep 30;done
```

peak load - load averages around 12.13 and 11574 postgres file handles


```
 21:07:10 up 1 day,  9:42,  2 users,  load average: 11.11, 12.13, 8.76
11574
postgres  5923     1  6 21:01 pts/0    00:00:19 pgbench -h localhost -p 6432 -d pgbbench -U bench1 -c 30 -j 30 -T 300 -f custom_bench_nowait.sql
postgres  5936 22334  4 21:01 ?        00:00:14 postgres: bench1 bench1 ::1(45794) SELECT
postgres  5964 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 127.0.0.1(46568) idle
postgres  5967 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 ::1(45808) idle
postgres  5968 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 127.0.0.1(46582) idle
postgres  5969 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 ::1(45818) SELECT
postgres  5970 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 127.0.0.1(46612) SELECT
postgres  5971 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 ::1(45856) SELECT
postgres  5972 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 127.0.0.1(46634) idle
postgres  5973 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 ::1(45870) idle
postgres  5974 22334  4 21:01 ?        00:00:13 postgres: bench1 bench1 127.0.0.1(46638) SELECT
root      6650  7886  0 21:07 pts/1    00:00:00 grep --color=auto bench
```

peak query rate 1003 queries/s

```
[pg10centos7:root:/var/log/pgbouncer] # grep 'LOG stats' pgbouncer.log
...
2019-02-22 21:04:32.050 5900 LOG stats: 1003 xacts/s, 1003 queries/s, in 27900 B/s, out 71212 B/s, xact 9375 us, query 9375 us, wait time 0 us
2019-02-22 21:05:32.019 5900 LOG stats: 752 xacts/s, 752 queries/s, in 21080 B/s, out 53453 B/s, xact 12638 us, query 12638 us, wait time 0 us
2019-02-22 21:06:32.021 5900 LOG stats: 726 xacts/s, 726 queries/s, in 20148 B/s, out 51560 B/s, xact 13126 us, query 13126 us, wait time 0 us
2019-02-22 21:07:32.088 5900 LOG stats: 680 xacts/s, 680 queries/s, in 19053 B/s, out 48314 B/s, xact 14005 us, query 14005 us, wait time 0 us
2019-02-22 21:08:32.019 5900 LOG stats: 336 xacts/s, 336 queries/s, in 9431 B/s, out 23941 B/s, xact 14039 us, query 14039 us, wait time 0 us```


## Tech Details - test two  - pgbench 30 concurrent test threads and pgbouncer pool with 20 connections 
```
pgbench -h localhost -p 6432 -d pgbbench -U bench1 -c 30 -j 30 -T 300 -f custom_bench_nowait.sql
```

connection pool size
```
[pg10centos7:root:/var/log/pgbouncer] # grep default_pool_size /etc/pgbouncer/pgbouncer.ini
default_pool_size = 20
```

monitoring script

```
[pg10centos7:root:/var/log/pgbouncer] # for i in {1..1000};do uptime;lsof | grep postgres | wc -l;ps -ef|grep bench;sleep 30;done
```

peak load - load averages around 21.8 and 22841 postgres file handles


```
 21:19:30 up 1 day,  9:54,  2 users,  load average: 21.80, 19.91, 14.24
22841
postgres  6989     1  1 21:09 pts/0    00:00:10 pgbench -h localhost -p 6432 -d pgbbench -U bench1 -c 30 -j 30 -T 300 -f custom_bench_nowait.sql
postgres  7010 22334  1 21:09 ?        00:00:11 postgres: bench1 bench1 ::1(45878) SELECT
postgres  7022 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 127.0.0.1(46652) SELECT
postgres  7024 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45888) SELECT
postgres  7030 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46668) SELECT
postgres  7031 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45906) SELECT
postgres  7034 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46678) SELECT
postgres  7045 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45914) SELECT
postgres  7046 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46718) SELECT
postgres  7047 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45954) SELECT
postgres  7048 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 127.0.0.1(46722) SELECT
postgres  7049 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45958) SELECT
postgres  7050 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46726) SELECT
postgres  7051 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 ::1(45962) SELECT
postgres  7052 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46730) SELECT
postgres  7053 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45966) SELECT
postgres  7054 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46734) SELECT
postgres  7055 22334  1 21:09 ?        00:00:10 postgres: bench1 bench1 ::1(45970) SELECT
postgres  7056 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46738) SELECT
postgres  7057 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 ::1(45974) SELECT
postgres  7058 22334  1 21:09 ?        00:00:09 postgres: bench1 bench1 127.0.0.1(46742) SELECT
postgres  7714 22334  2 21:19 ?        00:00:00 postgres: autovacuum worker process   bench1
```


peak query rate 418 queries/s

```
[pg10centos7:root:/var/log/pgbouncer] # grep 'LOG stats' pgbouncer.log
...
2019-02-22 21:19:37.182 6967 LOG stats: 0 xacts/s, 0 queries/s, in 1 B/s, out 3 B/s, xact 52006535 us, query 52006535 us, wait time 0 us
2019-02-22 21:20:37.036 6967 LOG stats: 92 xacts/s, 92 queries/s, in 2596 B/s, out 6586 B/s, xact 1139747 us, query 1139747 us, wait time 0 us
2019-02-22 21:21:37.117 6967 LOG stats: 418 xacts/s, 418 queries/s, in 11716 B/s, out 29708 B/s, xact 44417 us, query 44417 us, wait time 0 us
2019-02-22 21:22:37.023 6967 LOG stats: 91 xacts/s, 91 queries/s, in 2564 B/s, out 6559 B/s, xact 57510 us, query 57510 us, wait time 0 us
```


