\timing on
alter table pgbench_accounts add constraint pgbench_accounts_fk_bid foreign key (bid) references pgbench_branches (bid);
alter table pgbench_accounts add aname character(20);
update pgbench_accounts set aname = ('[0:3]={Ava,Alex,Aiden,Abigail}'::text[])[floor(random()*4)];
alter table pgbench_branches add mname character(20);
update pgbench_branches set mname = ('[0:3]={Bella,Brittany,Brenda,Belen}'::text[])[floor(random()*4)];
