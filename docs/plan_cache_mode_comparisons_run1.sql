-- extending test from https://franckpachot.medium.com/postgresql-bind-variable-peeking-fb4be4942252

drop table if exists demo; 
create table DEMO as select 1 n from generate_series(1,11)
           union all select 2   from generate_series(1,22)
           union all select 3   from generate_series(1,33)
           union all select 4   from generate_series(1,44)
           union all select 5   from generate_series(1,55)
           union all select 6   from generate_series(1,66)
           union all select 7   from generate_series(1,77)
           union all select 8   from generate_series(1,88)
           ;

analyze demo;
\d demo

\x
select * from pg_stats where tablename = 'demo' and attname = 'n';
\x

prepare myselect_auto (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=auto;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_auto(1);
explain (analyze,buffers) execute myselect_auto(1);
explain (analyze,buffers) execute myselect_auto(2);
explain (analyze,buffers) execute myselect_auto(3);
explain (analyze,buffers) execute myselect_auto(4);
explain (analyze,buffers) execute myselect_auto(5);
explain (analyze,buffers) execute myselect_auto(6);
explain (analyze,buffers) execute myselect_auto(7);
explain (analyze,buffers) execute myselect_auto(8);
explain (analyze,buffers) execute myselect_auto(9);


prepare myselect_force_generic_plan (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=force_generic_plan;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_force_generic_plan(1);
explain (analyze,buffers) execute myselect_force_generic_plan(1);
explain (analyze,buffers) execute myselect_force_generic_plan(2);
explain (analyze,buffers) execute myselect_force_generic_plan(3);
explain (analyze,buffers) execute myselect_force_generic_plan(4);
explain (analyze,buffers) execute myselect_force_generic_plan(5);
explain (analyze,buffers) execute myselect_force_generic_plan(6);
explain (analyze,buffers) execute myselect_force_generic_plan(7);
explain (analyze,buffers) execute myselect_force_generic_plan(8);
explain (analyze,buffers) execute myselect_force_generic_plan(9);


prepare myselect_force_custom_plan (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=force_custom_plan;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_force_custom_plan(1);
explain (analyze,buffers) execute myselect_force_custom_plan(1);
explain (analyze,buffers) execute myselect_force_custom_plan(2);
explain (analyze,buffers) execute myselect_force_custom_plan(3);
explain (analyze,buffers) execute myselect_force_custom_plan(4);
explain (analyze,buffers) execute myselect_force_custom_plan(5);
explain (analyze,buffers) execute myselect_force_custom_plan(6);
explain (analyze,buffers) execute myselect_force_custom_plan(7);
explain (analyze,buffers) execute myselect_force_custom_plan(8);
explain (analyze,buffers) execute myselect_force_custom_plan(9);


