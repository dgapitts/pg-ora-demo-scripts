set search_path = :vSchema;
select
   schemaname,
   relname,
   pg_size_pretty(pg_total_relation_size (relname::regclass)) as full_size,
   pg_size_pretty(pg_relation_size(relname::regclass)) as table_size,
   pg_size_pretty(pg_total_relation_size (relname::regclass) - pg_relation_size(relname::regclass)) as index_size,
   n_tup_upd,
   n_tup_hot_upd,
   n_live_tup, n_dead_tup
from
   pg_stat_user_tables
where relname in (:vTable)
  and schemaname in (:vSchema)
order by
   relname, n_tup_upd desc;
