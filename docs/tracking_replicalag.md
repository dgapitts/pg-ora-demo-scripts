### tracking replicalag
I like this [simple query for tracking replicalag](https://stackoverflow.com/questions/28323355/how-to-check-the-replication-delay-in-postgresql), although there a couple of minor issues for non-prod envs

```
select now() - pg_last_xact_replay_timestamp() AS replication_delay
```

Note initially on test cluster startup this blank

```
[pg13-db2:postgres:~] # psql -c "select now() - pg_last_xact_replay_timestamp() AS replication_delay"

┌───────────────────┐
│ replication_delay │
├───────────────────┤
│ ¤                 │
└───────────────────┘
(1 row)

Time: 0.694 ms
```

but once we start this processing we see a `replication_delay` although here this relfects that there have been no processing in the last 2.436 secs (2436ms)

```
[pg13-db2:postgres:~] # psql -c "select now() - pg_last_xact_replay_timestamp() AS replication_delay"

Welcome, my magistrate

┌───────────────────┐
│ replication_delay │
├───────────────────┤
│ 00:00:02.434626   │
└───────────────────┘
(1 row)
```

