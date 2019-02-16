select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

