== How to run - test one - sample script with 2 second sleep ==

=== Setup test script ===

I started with the extremely simple python script
```
~/projects/pg-ora-demo-scripts/memtest $ cat gen_sql.py
for i in range(10001):
    print "select * from tab"+str(i)+;"
    print "select now(), pg_sleep(2);"
```

and then generate you CREATE SQL statements via
```
~/projects/pg-ora-demo-scripts/memtest $ python gen_sql.py > custom_bench.sql
```

=== Sample run with 90 concurrent connections (with 2 second sleep between each table access) ===

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/memtest/bench_test] # pgbench -c 90 -j 90 -T 36000 -f custom_bench.sql
starting vacuum...ERROR:  relation "pgbench_branches" does not exist
(ignoring this error and continuing anyway)
ERROR:  relation "pgbench_tellers" does not exist
(ignoring this error and continuing anyway)
ERROR:  relation "pgbench_history" does not exist
(ignoring this error and continuing anyway)
end.
```

NB You can ignore these ERRORs ... we have not yet installed the default 3 table pgbench schema - as we're running as 10,000 table test

=== Monitor file handles ===

Approx 6,000 file handles per minute
```
[root@pg10centos7 ~]# for i in {1..1000};do uptime;lsof | grep postgres | wc -l;sleep 60;done
 22:32:27 up  1:01,  3 users,  load average: 1.09, 0.35, 0.15
18535
 22:33:28 up  1:02,  3 users,  load average: 0.40, 0.28, 0.14
24115
 22:34:29 up  1:03,  3 users,  load average: 0.78, 0.43, 0.20
29515
 22:35:30 up  1:04,  3 users,  load average: 0.33, 0.36, 0.19
35095
 22:36:31 up  1:05,  3 users,  load average: 0.17, 0.32, 0.19
40495
 22:37:32 up  1:06,  3 users,  load average: 0.06, 0.26, 0.18
46075
 22:38:34 up  1:07,  3 users,  load average: 0.02, 0.21, 0.17
51611
 22:39:36 up  1:08,  3 users,  load average: 0.09, 0.20, 0.17
57121
...
```

which is very approx double what I had expected given each process opens a new file handle every 2 seconds

```
$ echo '(60/2)*90'|bc
2700
```


=== File handle exhaustion after 10 mins ===


```
[pg10centos7:postgres:~/pg-ora-demo-scripts/memtest/bench_test] # pgbench -c 90 -j 90 -T 36000 -f custom_bench.sql
starting vacuum...ERROR:  relation "pgbench_branches" does not exist
(ignoring this error and continuing anyway)
ERROR:  relation "pgbench_tellers" does not exist
(ignoring this error and continuing anyway)
ERROR:  relation "pgbench_history" does not exist
(ignoring this error and continuing anyway)
end.
client 28 aborted in command 501 of script 0; ERROR:  epoll_create1 failed: Too many open files in system

client 35 aborted in command 501 of script 0; ERROR:  epoll_create1 failed: Too many open files in system

client 32 aborted in command 501 of script 0; ERROR:  epoll_create1 failed: Too many open files in system

client 11 aborted in command 501 of script 0; ERROR:  epoll_create1 failed: Too many open files in system

```


```
[root@pg10centos7 ~]# for i in {1..1000};do uptime;lsof | grep postgres | wc -l;sleep 60;done
 22:32:27 up  1:01,  3 users,  load average: 1.09, 0.35, 0.15
18535
 22:33:28 up  1:02,  3 users,  load average: 0.40, 0.28, 0.14
24115
 22:34:29 up  1:03,  3 users,  load average: 0.78, 0.43, 0.20
29515
 22:35:30 up  1:04,  3 users,  load average: 0.33, 0.36, 0.19
35095
 22:36:31 up  1:05,  3 users,  load average: 0.17, 0.32, 0.19
40495
 22:37:32 up  1:06,  3 users,  load average: 0.06, 0.26, 0.18
46075
 22:38:34 up  1:07,  3 users,  load average: 0.02, 0.21, 0.17
51611
 22:39:36 up  1:08,  3 users,  load average: 0.09, 0.20, 0.17
57121
 22:40:38 up  1:09,  3 users,  load average: 0.06, 0.18, 0.16
62749
 22:41:40 up  1:10,  3 users,  load average: 0.02, 0.15, 0.15
53458
```

nothing stands out in the sar data:

```
[root@pg10centos7 ~]# sar -r|head -5;sar -r|tail -12
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
10:34:01 PM    142828    355912     71.36         0     71320   1559492     60.08    153640     57856         0
10:35:01 PM    114504    384236     77.04         0     71280   1559492     60.08    170544     57896         0
10:36:01 PM     86272    412468     82.70         0     71752   1568864     60.44    186908     58344         0
10:37:01 PM     55752    442988     88.82         0     71764   1661384     64.00    205580     58344         0
10:38:01 PM     24712    474028     95.05         0     71768   1675120     64.53    224948     58344         0
10:39:01 PM     20564    478176     95.88         0     63872   1675120     64.53    195432    100212         0
10:40:01 PM     25332    473408     94.92         0     63740   1687248     65.00    150396    161656         0
10:41:01 PM     87084    411656     82.54         0     55788   1597672     61.55    133628    142844        32
10:42:01 PM     22292    476448     95.53         0     47956   1605412     61.84    138716    143092         0
10:43:01 PM    354784    143956     28.86         0     52136    467132     18.00     28236     41196         0
10:44:01 PM    354620    144120     28.90         0     52188    467132     18.00     28260     41340         0
Average:        66951    431789     86.58       634     77541   1040193     40.07    154261    131283         1
[root@pg10centos7 ~]# sar -q|head -5;sar -q|tail -12
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM   runq-sz  plist-sz   ldavg-1   ldavg-5  ldavg-15   blocked
10:34:01 PM         1       311      1.18      0.47      0.21         0
10:35:01 PM         1       311      0.50      0.40      0.20         0
10:36:01 PM         1       311      0.28      0.35      0.20         0
10:37:01 PM         1       310      0.10      0.29      0.19         0
10:38:01 PM         1       311      0.04      0.24      0.18         0
10:39:01 PM         0       310      0.15      0.23      0.17         0
10:40:01 PM         2       313      0.11      0.20      0.17         0
10:41:01 PM         1       275      0.04      0.16      0.16         0
10:42:01 PM         0       275      0.07      0.15      0.15         0
10:43:01 PM         0       131      0.03      0.12      0.14         0
10:44:01 PM         1       131      0.01      0.10      0.13         0
Average:            1       199      0.11      0.10      0.08         0
[root@pg10centos7 ~]# sar -u|head -5;sar -u|tail -12
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM     CPU     %user     %nice   %system   %iowait    %steal     %idle
10:34:01 PM     all      0.61      0.00      0.62      0.00      0.00     98.77
10:35:01 PM     all      0.68      0.00      0.62      0.00      0.00     98.70
10:36:01 PM     all      0.72      0.00      0.74      0.01      0.00     98.53
10:37:01 PM     all      0.75      0.00      0.82      0.00      0.00     98.43
10:38:01 PM     all      0.80      0.00      0.93      0.00      0.00     98.27
10:39:01 PM     all      0.70      0.00      0.92      0.00      0.00     98.37
10:40:01 PM     all      0.81      0.00      1.28      0.02      0.00     97.90
10:41:01 PM     all      0.84      0.00      1.32      0.01      0.00     97.83
10:42:01 PM     all      0.73      0.00      1.24      0.01      0.00     98.02
10:43:01 PM     all      0.13      0.00      0.28      0.02      0.00     99.57
10:44:01 PM     all      0.06      0.00      0.09      0.00      0.00     99.85
Average:        all      0.38      0.00      0.64      0.03      0.00     98.95
```

the postgres db is now down

```
[root@pg10centos7 ~]# systemctl status postgresql-10.service
● postgresql-10.service - PostgreSQL 10 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-10.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2019-01-31 21:31:01 UTC; 1h 16min ago
     Docs: https://www.postgresql.org/docs/10/static/
  Process: 2454 ExecStartPre=/usr/pgsql-10/bin/postgresql-10-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)
 Main PID: 2477 (postmaster)
   CGroup: /system.slice/postgresql-10.service
           ├─2477 /usr/pgsql-10/bin/postmaster -D /var/lib/pgsql/10/data/
           ├─2775 postgres: checkpointer process
           ├─2776 postgres: writer process
           ├─2777 postgres: wal writer process
           ├─2778 postgres: autovacuum launcher process
           ├─2779 postgres: stats collector process
           ├─2780 postgres: bgworker: logical replication launcher
           ├─5550 postgres: logger process
           └─5660 postgres: postgres postgres [local] idle

Jan 31 21:30:57 pg10centos7 systemd[1]: Starting PostgreSQL 10 database server...
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.358 UTC [2477] LOG:  listening on IPv6 address "::1", port 5432
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.359 UTC [2477] LOG:  listening on IPv4 address "127.0.0.1", port 5432
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.361 UTC [2477] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.369 UTC [2477] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.473 UTC [2477] LOG:  redirecting log output to logging collector process
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.473 UTC [2477] HINT:  Future log output will appear in directory "log".
Jan 31 21:31:01 pg10centos7 systemd[1]: Started PostgreSQL 10 database server.
Jan 31 22:40:45 pg10centos7 postmaster[2477]: 2019-01-31 22:40:45.736 UTC [2516] FATAL:  epoll_create1 failed: Too many open files in system
[root@pg10centos7 ~]# systemctl stop postgresql-10.service
[root@pg10centos7 ~]# systemctl status postgresql-10.service
● postgresql-10.service - PostgreSQL 10 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-10.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Thu 2019-01-31 22:47:18 UTC; 1s ago
     Docs: https://www.postgresql.org/docs/10/static/
  Process: 2477 ExecStart=/usr/pgsql-10/bin/postmaster -D ${PGDATA} (code=exited, status=0/SUCCESS)
  Process: 2454 ExecStartPre=/usr/pgsql-10/bin/postgresql-10-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)
 Main PID: 2477 (code=exited, status=0/SUCCESS)

Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.358 UTC [2477] LOG:  listening on IPv6 address "::1", port 5432
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.359 UTC [2477] LOG:  listening on IPv4 address "127.0.0.1", port 5432
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.361 UTC [2477] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.369 UTC [2477] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.473 UTC [2477] LOG:  redirecting log output to logging collector process
Jan 31 21:30:57 pg10centos7 postmaster[2477]: 2019-01-31 21:30:57.473 UTC [2477] HINT:  Future log output will appear in directory "log".
Jan 31 21:31:01 pg10centos7 systemd[1]: Started PostgreSQL 10 database server.
Jan 31 22:40:45 pg10centos7 postmaster[2477]: 2019-01-31 22:40:45.736 UTC [2516] FATAL:  epoll_create1 failed: Too many open files in system
Jan 31 22:47:18 pg10centos7 systemd[1]: Stopping PostgreSQL 10 database server...
Jan 31 22:47:18 pg10centos7 systemd[1]: Stopped PostgreSQL 10 database server.
```

