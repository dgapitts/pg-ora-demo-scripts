## pg_stat_activity and pg_sleep

Couple of points to highlight
* example below show difference between implicit and explicit transactions
* pg_sleep is an "active" query (this is what promoted me on this whole thread / mini-investigation)
* backend_start is important in postgres, in a real-world system you may want to prune off sessions which have been ideal for a long time

### example 1 - implicit transaction

*  implicit transaction starts with query

davep=# select pg_sleep(120);
^CCancel request sent
ERROR:  canceling statement due to user request

outputoutput which this was running (from another session)

davep=# select query, state,  query_start, xact_start,  backend_start from pg_stat_activity where state <> 'idle' and query not like '%pg_stat_activity%';
-[ RECORD 1 ]-+------------------------------
query         | select pg_sleep(120);
state         | active
query_start   | 2021-12-31 15:37:30.853873+01
xact_start    | 2021-12-31 15:37:30.853873+01
backend_start | 2021-12-31 09:54:40.834681+01


### example 2 - explicit transaction
* explicit transaction

davep=# begin;
BEGIN
davep=*# select pg_sleep(120);
 pg_sleep
----------

(1 row)

davep=*# end;
COMMIT

output which this was running (from another session)

davep=# select query, state,  query_start, xact_start,  backend_start from pg_stat_activity where state <> 'idle' and query not like '%pg_stat_activity%';
-[ RECORD 1 ]-+------------------------------
query         | select pg_sleep(120);
state         | active
query_start   | 2021-12-31 15:39:09.201021+01
xact_start    | 2021-12-31 15:39:05.860719+01
backend_start | 2021-12-31 09:54:40.834681+01
```

