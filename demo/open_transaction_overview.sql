select datname,application_name,xact_start,query from pg_stat_activity where xact_start is not null and query not like '%query from pg_stat_activity%';
