-- active: The backend is executing a query.
-- idle: The backend is waiting for a new client command.
-- active: The backend is executing a query.
-- idle: The backend is waiting for a new client command.
-- idle in transaction: The backend is in a transaction, but is not currently executing a query.
-- idle in transaction (aborted): This state is similar to idle in transaction, except one of the statements in the transaction caused an error.
-- fastpath function call: The backend is executing a fast-path function.
-- disabled: This state is reported if track_activities is disabled in this backend.

SELECT md5(query),
left(query,75) AS query_first_75,
left((now()-query_start)::text,12) AS duration,
left(query_start::text,22) AS query_start,
(CASE
        WHEN state = 'active' THEN 'ACT'
        WHEN state = 'idle' THEN 'idle'
        WHEN state = 'idle in transaction' THEN 'IiT'
        WHEN state = 'idle in transaction (aborted)' THEN 'IitA'
        WHEN state = 'fastpath function call' THEN 'ffc'
        WHEN state = 'disabled' THEN 'disabled'
        ELSE '???'
END) as STAT,
client_addr,
pid  AS pid
FROM pg_stat_activity
WHERE state <> 'idle'
  AND pid<>pg_backend_pid()
ORDER BY 4;
