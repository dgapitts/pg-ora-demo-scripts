-- Extract top 50 query text by elapsed time i.e pg_stat_statements.total_time (before running reset)

\x on
(SELECT md5(query::text), queryid, query FROM pg_stat_statements where query NOT IN ('BEGIN','ROLLBACK','COMMIT')  ORDER BY total_time DESC LIMIT 50) UNION (SELECT md5(query::text), queryid, query FROM pg_stat_statements where query NOT IN ('BEGIN','ROLLBACK','COMMIT')  ORDER BY Calls DESC LIMIT 50);
