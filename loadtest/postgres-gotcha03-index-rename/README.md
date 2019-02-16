## Summary - blocked index renamea

Arond moderately heavy SELECT load we see `alter index ... rename to ...` calls getting blocked

## Session 1 pgbench script - heavy/slow SELECTs

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/loadtest/postgres-gotcha03-index-rename] # pgbench -c 20 -T30 -h localhost -p 5432 -U bench1  -d bench1 -f custom.sql
```

and 

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/loadtest/postgres-gotcha03-index-rename] # cat custom.sql
select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
```

## Session 2 index rename

```
bench1=> alter index pgbench_branches_pkey rename to pgbench_branches_pk1;
ALTER INDEX
Time: 1693.076 ms (00:01.693)
bench1=> alter index pgbench_branches_pk1 rename to pgbench_branches_pkey;
ALTER INDEX
Time: 5490.673 ms (00:05.491)
```

and 

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/pgmon] # uptime
 21:00:09 up 11 min,  3 users,  load average: 4.09, 1.83, 1.00
```


## Session 3 monitoring

```
[pg10centos7:postgres:~/pg-ora-demo-scripts/pgmon] # for i in {1..100};do psql -f block_sess_mon.sql;sleep 1;done

 blocked_pid | blocked_user | blocking_pid | blocking_user | blocked_statement | current_statement_in_blocking_process
-------------+--------------+--------------+---------------+-------------------+---------------------------------------
(0 rows)

^C
[pg10centos7:postgres:~/pg-ora-demo-scripts/pgmon] # for i in {1..100};do psql -f block_sess_mon.sql;sleep 1;done
 blocked_pid | blocked_user | blocking_pid | blocking_user | blocked_statement | current_statement_in_blocking_process
-------------+--------------+--------------+---------------+-------------------+---------------------------------------
(0 rows)

 blocked_pid | blocked_user | blocking_pid | blocking_user |                         blocked_statement                         |                            current_sta
tement_in_blocking_process
-------------+--------------+--------------+---------------+-------------------------------------------------------------------+---------------------------------------
-------------------------------------------------------
        4533 | bench1       |         4559 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4556 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4560 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4564 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4546 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4551 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4552 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4563 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4547 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4558 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4545 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4554 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4557 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4553 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4562 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4561 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4548 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4555 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4549 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
        4533 | bench1       |         4550 | bench1        | alter index pgbench_branches_pkey rename to pgbench_branches_pk1; | select count(bid) from pgbench_branche
s where bid NOT IN (select bid from pgbench_accounts);
(20 rows)
```

