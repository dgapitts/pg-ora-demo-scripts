explain (analyze, buffers) (select 1 from pgbench_branches UNION ALL select 1 from pgbench_accounts) limit 1;
explain (analyze, buffers) (select 1 from pgbench_branches UNION  select 1 from pgbench_accounts) limit 1;
