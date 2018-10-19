# Summary

These scripts 
* demo pgbench again, this time with the -n (no vacuum) option, it is not immediately clear to me why pgbench runs vacuum after inserting/loading the data (beyond that this provides table stats)
* illustrate how VACUUM FULL can be very quickly become disruptive for standard OLTP processing, typically you need downtime to run VACUUM FULL 
* demo the blocking and waiting scripts

# Automated script to demo the conflict between VACUUM FULL and normal OLTP operations

```
[pg96centos7:postgres:~/pg-ora-demo-scripts/loadtest/postgres-gotcha03-vacuum-full] # cat run_vacuum_full_test.sh

#echo 'setup generic pgbench data ... lots of insert'
pgbench -i -s 50  -n -h localhost -p 5432 -U bench1  -d bench1

echo 'start running a basic load test with a mixture of SELECT/UPDATE/DELETE/INSERT statements'
pgbench -c 32 -n -T 30  --username=bench1  -d bench1 &

sleep 15

echo 'after 15 seconds kick off VACUUM FULL'
psql -U bench1 -f demo_vacuum_full.sql
```

# Sample output 

```
[pg96centos7:postgres:~/pg-ora-demo-scripts/logs] # grep 'block\|vacuum' 10-19-2018.1435.block_sess_mon.log
...
 blocked_pid | blocked_user | blocking_pid | blocking_user |                              blocked_statement                               |                    current_statement_in_blocking_process
        4231 | bench1       |         4271 | bench1        | UPDATE pgbench_accounts SET abalance = abalance + -1795 WHERE aid = 4472459; | vacuum full pgbench_accounts;
        4232 | bench1       |         4271 | bench1        | UPDATE pgbench_accounts SET abalance = abalance + -540 WHERE aid = 3708274;  | vacuum full pgbench_accounts;
        4233 | bench1       |         4271 | bench1        | UPDATE pgbench_accounts SET abalance = abalance + -4568 WHERE aid = 4404212; | vacuum full pgbench_accounts;
        4234 | bench1       |         4271 | bench1        | UPDATE pgbench_accounts SET abalance = abalance + -74 WHERE aid = 218983;    | vacuum full pgbench_accounts;
...
```
