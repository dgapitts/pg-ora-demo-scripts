explain (analyze, buffers) (select 1 from pgbench_branches) UNION ALL (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) select 1 from pgbench_branches UNION ALL select 1 from pgbench_accounts limit 1;
explain (analyze, buffers) (select 1 from pgbench_branches) UNION  (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) (select 1 from pgbench_branches) UNION (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) (select 1 from pgbench_branches) UNION (select 1 from pgbench_accounts) limit 1;
explain (analyze, buffers) select 1 from pgbench_branches UNION select 1 from pgbench_accounts limit 1;
explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
