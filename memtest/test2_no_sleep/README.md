## Test setup details - 10000 table test run heavily in parallel

10,000 table test 
```
[pg10centos7:postgres:~/pg-ora-demo-scripts/memtest/test2_no_sleep] # cat custom_bench_nowait.sql
select * from tab0;
select * from tab1;
select * from tab2;
..
select * from tab9997;
select * from tab9998;
select * from tab9999;
select * from tab10000;
```

run over several batches 

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/memtest/test2_no_sleep] # cat wrapper_script_batches_of_10.sh
uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

uptime
pgbench -c 10 -j 10 -T 300 -f custom_bench_nowait.sql &
sleep 5
uptime
sleep 55

```

these tests eventually started to fail at around 50K postgres file handles

```
could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"?
connection to database "" failed:
could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"?
connection to database "" failed:
could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/var/run/postgresq
```


## Test execution details 

load averages and postgres file handles

```
[root@pg10centos7 ~]# for i in {1..1000};do uptime;lsof | grep postgres | wc -l;sleep 60;done
 22:57:39 up  1:26,  3 users,  load average: 0.05, 0.03, 0.06
14
 22:58:39 up  1:27,  3 users,  load average: 0.65, 0.17, 0.10
11505
 22:59:41 up  1:28,  3 users,  load average: 6.74, 2.03, 0.74
11504
 23:00:43 up  1:29,  3 users,  load average: 9.22, 3.60, 1.36
11505
 23:01:45 up  1:30,  3 users,  load average: 10.43, 5.00, 1.99
11523
 23:02:48 up  1:31,  3 users,  load average: 15.78, 7.47, 3.03
22496
 23:03:53 up  1:33,  3 users,  load average: 24.25, 11.45, 4.70
33499
 23:05:00 up  1:34,  3 users,  load average: 33.60, 16.57, 6.92
44470
 23:06:14 up  1:35,  3 users,  load average: 42.39, 23.01, 9.91
47739
 23:07:21 up  1:36,  3 users,  load average: 35.64, 25.55, 11.78
51914
 23:08:27 up  1:37,  3 users,  load average: 23.39, 23.88, 12.13
51913
 23:09:32 up  1:38,  3 users,  load average: 9.95, 19.89, 11.55
48588
```



sar (sysstat) monitoring

```
[root@pg10centos7 ~]# top -b -n 5 > top-5iterations.txt
[root@pg10centos7 ~]# sar -r|head -5;sar -r|tail -12
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
10:56:01 PM    370116    128624     25.79         0     40368    296368     11.42     26636     30648         0
10:57:01 PM    364452    134288     26.93         0     40476    302424     11.65     31780     30236         8
10:58:01 PM    363524    135216     27.11         0     41092    302768     11.66     32232     30560         0
10:59:02 PM      5628    493112     98.87         0     29724   1205612     46.44    158732    253912         8
11:00:02 PM     10132    488608     97.97         0     32392   1304704     50.26    203140    202228         4
11:01:02 PM     10464    488276     97.90         0     32252   1306212     50.32    201988    201856         4
11:02:03 PM     11036    487704     97.79         0     31180   1309952     50.46    199460    203860         8
11:03:08 PM      5852    492888     98.83         0     20512   1774020     68.34    197116    202240        92
11:04:16 PM      6100    492640     98.78         0     23424   2216060     85.37    189516    198220        16
11:05:23 PM      6392    492348     98.72         0     22964   2553744     98.38    190484    189928         0
11:06:25 PM      6764    491976     98.64         0     21048   2870460    110.58    180408    191136         0
Average:       106056    392684     78.74       487     68100   1001979     38.60    138411    123168         3
[root@pg10centos7 ~]# sar -r|head -5;sar -r|tail -10
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
10:58:01 PM    363524    135216     27.11         0     41092    302768     11.66     32232     30560         0
10:59:02 PM      5628    493112     98.87         0     29724   1205612     46.44    158732    253912         8
11:00:02 PM     10132    488608     97.97         0     32392   1304704     50.26    203140    202228         4
11:01:02 PM     10464    488276     97.90         0     32252   1306212     50.32    201988    201856         4
11:02:03 PM     11036    487704     97.79         0     31180   1309952     50.46    199460    203860         8
11:03:08 PM      5852    492888     98.83         0     20512   1774020     68.34    197116    202240        92
11:04:16 PM      6100    492640     98.78         0     23424   2216060     85.37    189516    198220        16
11:05:23 PM      6392    492348     98.72         0     22964   2553744     98.38    190484    189928         0
11:06:25 PM      6764    491976     98.64         0     21048   2870460    110.58    180408    191136         0
Average:       106056    392684     78.74       487     68100   1001979     38.60    138411    123168         3
[root@pg10centos7 ~]# sar -r|head -5;sar -r|tail -11
Linux 3.10.0-957.1.3.el7.x86_64 (pg10centos7) 	01/31/2019 	_x86_64_	(2 CPU)

09:30:53 PM       LINUX RESTART

09:31:01 PM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
10:57:01 PM    364452    134288     26.93         0     40476    302424     11.65     31780     30236         8
10:58:01 PM    363524    135216     27.11         0     41092    302768     11.66     32232     30560         0
10:59:02 PM      5628    493112     98.87         0     29724   1205612     46.44    158732    253912         8
11:00:02 PM     10132    488608     97.97         0     32392   1304704     50.26    203140    202228         4
11:01:02 PM     10464    488276     97.90         0     32252   1306212     50.32    201988    201856         4
11:02:03 PM     11036    487704     97.79         0     31180   1309952     50.46    199460    203860         8
11:03:08 PM      5852    492888     98.83         0     20512   1774020     68.34    197116    202240        92
11:04:16 PM      6100    492640     98.78         0     23424   2216060     85.37    189516    198220        16
11:05:23 PM      6392    492348     98.72         0     22964   2553744     98.38    190484    189928         0
11:06:25 PM      6764    491976     98.64         0     21048   2870460    110.58    180408    191136         0
Average:       106056    392684     78.74       487     68100   1001979     38.60    138411    123168         3
```

and some top load details 


```
[root@pg10centos7 ~]# grep -A20 ^top top-5iterations.txt
top - 23:05:31 up  1:34,  3 users,  load average: 38.22, 19.32, 8.14
Tasks: 160 total,   2 running, 158 sleeping,   0 stopped,   0 zombie
%Cpu(s): 10.0 us, 16.2 sy,  0.0 ni,  0.0 id, 45.0 wa,  0.0 hi, 28.8 si,  0.0 st
KiB Mem :   498740 total,     5772 free,   410396 used,    82572 buff/cache
KiB Swap:  2097148 total,   621552 free,  1475596 used.    22072 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
   39 root      20   0       0      0      0 S  10.5  0.0   1:00.49 kswapd0
 6156 postgres  20   0  307972  10196   4500 D   5.3  2.0   0:01.04 postmaster
 5945 postgres  20   0  368932   8844   3288 D   2.6  1.8   0:22.58 postmaster
 5946 postgres  20   0  368932   8812   3272 D   2.6  1.8   0:22.84 postmaster
 5949 postgres  20   0  369040   8920   3288 D   2.6  1.8   0:22.71 postmaster
 6068 postgres  20   0  343592   9392   3292 D   2.6  1.9   0:04.31 postmaster
 6070 postgres  20   0  343628   9472   3292 D   2.6  1.9   0:04.27 postmaster
 6112 postgres  20   0  329540   9452   3424 D   2.6  1.9   0:02.45 postmaster
 6115 postgres  20   0  329532   9448   3420 D   2.6  1.9   0:02.38 postmaster
 6118 postgres  20   0  329556   9356   3420 D   2.6  1.9   0:02.34 postmaster
 6150 postgres  20   0  307968  10312   4536 D   2.6  2.1   0:00.98 postmaster
 6151 postgres  20   0  307968  10276   4520 D   2.6  2.1   0:00.97 postmaster
 6154 postgres  20   0  307968  10336   4532 D   2.6  2.1   0:00.93 postmaster
 6157 postgres  20   0  307968  10320   4536 D   2.6  2.1   0:00.91 postmaster
--
top - 23:05:37 up  1:34,  3 users,  load average: 39.28, 20.17, 8.54
Tasks: 160 total,  10 running, 150 sleeping,   0 stopped,   0 zombie
%Cpu(s):  3.1 us,  5.1 sy,  0.0 ni,  0.0 id, 79.4 wa,  0.0 hi, 12.4 si,  0.0 st
KiB Mem :   498740 total,    14640 free,   400600 used,    83500 buff/cache
KiB Swap:  2097148 total,   614380 free,  1482768 used.    31952 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
   39 root      20   0       0      0      0 S   5.9  0.0   1:00.83 kswapd0
 6167 postgres  20   0  297176   5996   5052 D   1.4  1.2   0:00.33 postmaster
 6114 postgres  20   0  329656   9380   3400 R   0.9  1.9   0:02.39 postmaster
 6152 postgres  20   0  316284  10352   4364 D   0.9  2.1   0:00.97 postmaster
 6172 postgres  20   0  297252   6564   5700 D   0.9  1.3   0:00.30 postmaster
 5926 postgres  20   0  296156   2232   1944 S   0.7  0.4   0:00.43 postmaster
 6067 postgres  20   0  343572   9568   3320 D   0.7  1.9   0:04.36 postmaster
 6072 postgres  20   0  343624   9556   3320 D   0.7  1.9   0:04.34 postmaster
 6074 postgres  20   0  343572   9480   3312 R   0.7  1.9   0:04.29 postmaster
 6109 postgres  20   0  329596   9272   3388 D   0.7  1.9   0:02.44 postmaster
 6111 postgres  20   0  329652   9340   3404 D   0.7  1.9   0:02.36 postmaster
 6113 postgres  20   0  329656   9316   3404 D   0.7  1.9   0:02.46 postmaster
 6116 postgres  20   0  329652   9376   3404 D   0.7  1.9   0:02.43 postmaster
 6150 postgres  20   0  316284  10184   4332 D   0.7  2.0   0:01.02 postmaster
--
top - 23:05:40 up  1:34,  3 users,  load average: 39.28, 20.17, 8.54
Tasks: 159 total,   1 running, 158 sleeping,   0 stopped,   0 zombie
%Cpu(s):  5.8 us, 10.4 sy,  0.0 ni,  0.0 id, 54.2 wa,  0.0 hi, 29.6 si,  0.0 st
KiB Mem :   498740 total,     7036 free,   413124 used,    78580 buff/cache
KiB Swap:  2097148 total,   606232 free,  1490916 used.    21076 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
   39 root      20   0       0      0      0 S  13.8  0.0   1:01.26 kswapd0
 6068 postgres  20   0  343712   9516   3320 D   1.6  1.9   0:04.39 postmaster
 6151 postgres  20   0  316800  10236   4256 D   1.6  2.1   0:01.05 postmaster
 6152 postgres  20   0  316800  10220   4252 D   1.6  2.0   0:01.02 postmaster
 6153 postgres  20   0  316804  10148   4244 D   1.6  2.0   0:01.02 postmaster
 6155 postgres  20   0  316800  10252   4264 D   1.6  2.1   0:01.03 postmaster
 6159 postgres  20   0  316800  10204   4256 D   1.6  2.0   0:01.08 postmaster
 5945 postgres  20   0  368932   8660   3420 D   1.3  1.7   0:22.65 postmaster
 5947 postgres  20   0  368932   8796   3448 D   1.3  1.8   0:22.79 postmaster
 6066 postgres  20   0  343696   9600   3320 D   1.3  1.9   0:04.45 postmaster
 6067 postgres  20   0  343692   9584   3312 D   1.3  1.9   0:04.40 postmaster
 6069 postgres  20   0  343620   9476   3304 D   1.3  1.9   0:04.33 postmaster
 6072 postgres  20   0  343624   9480   3304 D   1.3  1.9   0:04.38 postmaster
 6073 postgres  20   0  343608   9540   3308 D   1.3  1.9   0:04.38 postmaster
--
top - 23:05:43 up  1:34,  3 users,  load average: 39.98, 20.63, 8.75
Tasks: 159 total,   1 running, 158 sleeping,   0 stopped,   0 zombie
%Cpu(s):  6.4 us,  9.1 sy,  0.0 ni,  0.2 id, 55.8 wa,  0.0 hi, 28.5 si,  0.0 st
KiB Mem :   498740 total,     6476 free,   415224 used,    77040 buff/cache
KiB Swap:  2097148 total,   606988 free,  1490160 used.    20264 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
   39 root      20   0       0      0      0 S  11.6  0.0   1:01.64 kswapd0
 6157 postgres  20   0  316920  10508   4276 D   1.8  2.1   0:01.04 postmaster
 5952 postgres  20   0  368936   8816   3468 D   1.5  1.8   0:22.83 postmaster
 6070 postgres  20   0  351944   9940   3372 D   1.5  2.0   0:04.38 postmaster
 6150 postgres  20   0  316920  10492   4268 D   1.5  2.1   0:01.11 postmaster
 6151 postgres  20   0  316920  10516   4264 D   1.5  2.1   0:01.10 postmaster
 6154 postgres  20   0  316920  10536   4268 D   1.5  2.1   0:01.05 postmaster
 6156 postgres  20   0  316924  10428   4252 D   1.5  2.1   0:01.16 postmaster
 6158 postgres  20   0  316920  10516   4288 D   1.5  2.1   0:01.09 postmaster
 5947 postgres  20   0  368932   8860   3476 D   1.2  1.8   0:22.83 postmaster
 5948 postgres  20   0  369040   8908   3492 D   1.2  1.8   0:22.70 postmaster
 5949 postgres  20   0  369040   8860   3480 D   1.2  1.8   0:22.80 postmaster
 5950 postgres  20   0  368936   8928   3484 D   1.2  1.8   0:22.60 postmaster
 5953 postgres  20   0  368936   8824   3476 D   1.2  1.8   0:22.60 postmaster
--
top - 23:05:47 up  1:34,  3 users,  load average: 40.06, 20.97, 8.92
Tasks: 159 total,  16 running, 143 sleeping,   0 stopped,   0 zombie
%Cpu(s):  6.6 us,  9.3 sy,  0.0 ni,  0.2 id, 55.2 wa,  0.0 hi, 28.7 si,  0.0 st
KiB Mem :   498740 total,    13396 free,   405496 used,    79848 buff/cache
KiB Swap:  2097148 total,   595164 free,  1501984 used.    30308 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
   39 root      20   0       0      0      0 R  11.9  0.0   1:02.04 kswapd0
 5930 postgres  20   0  155124   4260    264 S   1.5  0.9   0:02.87 postmaster
 6153 postgres  20   0  316924  10472   4208 R   1.5  2.1   0:01.11 postmaster
 6154 postgres  20   0  316920  10428   4192 R   1.5  2.1   0:01.10 postmaster
 6155 postgres  20   0  316920  10516   4224 R   1.5  2.1   0:01.12 postmaster
 6156 postgres  20   0  316924  10464   4208 D   1.5  2.1   0:01.21 postmaster
 6158 postgres  20   0  316920  10564   4248 D   1.5  2.1   0:01.14 postmaster
 6159 postgres  20   0  316920  10400   4192 R   1.5  2.1   0:01.17 postmaster
 5945 postgres  20   0  368932   8632   3424 D   1.2  1.7   0:22.72 postmaster
 5946 postgres  20   0  368932   8696   3428 D   1.2  1.7   0:22.97 postmaster
 6066 postgres  20   0  351892   9840   3336 D   1.2  2.0   0:04.53 postmaster
 6067 postgres  20   0  351888   9876   3336 D   1.2  2.0   0:04.48 postmaster
 6071 postgres  20   0  351924   9896   3340 R   1.2  2.0   0:04.35 postmaster
 6072 postgres  20   0  351940   9952   3356 D   1.2  2.0   0:04.45 postmaster
 ```

