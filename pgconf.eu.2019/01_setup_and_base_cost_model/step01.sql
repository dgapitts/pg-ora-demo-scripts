
\timing on
set max_parallel_workers_per_gather = 0;
CREATE TABLE t_test (id SERIAL,  name  VARCHAR(20) NOT NULL, salary numeric default random()*10000);
\d t_test
insert into t_test (name) values ('dave');
insert into t_test (name) values ('thomas');
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
insert into t_test (name) (select name from t_test);
explain select * from t_test;
analyze;
explain select * from t_test;
\x
select * from pg_stats where tablename = 't_test';
\x off
show seq_page_cost;
show cpu_tuple_cost;
show cpu_operator_cost;
explain select * from t_test;
select pg_relation_size('t_test')/8192.0;
select 1*53431 + 0.01*8388562;
explain select count(*) from t_test;
select 1*53431 + 0.01*8388562 + 0.0025*8388562;
