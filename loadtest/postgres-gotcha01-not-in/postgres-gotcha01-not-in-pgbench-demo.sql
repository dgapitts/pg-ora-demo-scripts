<<<<<<< HEAD
\timing on

delete from pgbench_branches where bid in (998,999);
insert into pgbench_branches values (998,0,'dummy branch 998');
insert into pgbench_branches values (999,0,'dummy branch 999');
create index pgbench_accounts_bid on pgbench_accounts(bid);



explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);

select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
=======
explain (analyze, buffers) (select 1 from pgbench_branches) UNION ALL (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) select 1 from pgbench_branches UNION ALL select 1 from pgbench_accounts limit 1;
explain (analyze, buffers) (select 1 from pgbench_branches) UNION  (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) (select 1 from pgbench_branches) UNION (select 1 from pgbench_accounts limit 1);
explain (analyze, buffers) (select 1 from pgbench_branches) UNION (select 1 from pgbench_accounts) limit 1;
explain (analyze, buffers) select 1 from pgbench_branches UNION select 1 from pgbench_accounts limit 1;
explain (analyze, buffers) select count(bid) from pgbench_branches branch where NOT EXISTS (select * from pgbench_accounts account where account.bid = branch.bid);
explain (analyze, buffers) select count(bid) from pgbench_branches where bid NOT IN (select bid from pgbench_accounts);
>>>>>>> 7876a445f3a18b153267efaa1f38383a2be54595
