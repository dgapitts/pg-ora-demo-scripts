-- extending test from https://franckpachot.medium.com/postgresql-bind-variable-peeking-fb4be4942252

drop table if exists demo; 
create table DEMO as select 1 n from generate_series(1,1)
           union all select 2   from generate_series(1,2)
           union all select 3   from generate_series(1,4)
           union all select 4   from generate_series(1,8)
           union all select 5   from generate_series(1,16)
           union all select 6   from generate_series(1,32)
           union all select 7   from generate_series(1,64)
           union all select 8   from generate_series(1,128)
           union all select 9   from generate_series(1,256)
           union all select 10  from generate_series(1,518)
           union all select 11  from generate_series(1,1024)
           union all select 12  from generate_series(1,2048)
           union all select 13  from generate_series(1,4096)
           ;

create index demo_n on demo(n);
 
analyze demo;
\d demo

\x
select * from pg_stats where tablename = 'demo' and attname = 'n';
\x

prepare myselect_auto (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=auto;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_auto(1);
explain (analyze,buffers) execute myselect_auto(2);
explain (analyze,buffers) execute myselect_auto(3);
explain (analyze,buffers) execute myselect_auto(1);
explain (analyze,buffers) execute myselect_auto(2);
explain (analyze,buffers) execute myselect_auto(3);
explain (analyze,buffers) execute myselect_auto(4);
explain (analyze,buffers) execute myselect_auto(5);
explain (analyze,buffers) execute myselect_auto(6);
explain (analyze,buffers) execute myselect_auto(13);


prepare myselect_force_generic_plan (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=force_generic_plan;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_force_generic_plan(1);
explain (analyze,buffers) execute myselect_force_generic_plan(13);

prepare myselect_force_custom_plan (int) as select count(*) from DEMO where n=$1;
set plan_cache_mode=force_custom_plan;
show  plan_cache_mode;
explain (analyze,buffers) execute myselect_force_custom_plan(1);
explain (analyze,buffers) execute myselect_force_custom_plan(2);
explain (analyze,buffers) execute myselect_force_custom_plan(3);
explain (analyze,buffers) execute myselect_force_custom_plan(1);
explain (analyze,buffers) execute myselect_force_custom_plan(2);
explain (analyze,buffers) execute myselect_force_custom_plan(3);
explain (analyze,buffers) execute myselect_force_custom_plan(4);
explain (analyze,buffers) execute myselect_force_custom_plan(5);
explain (analyze,buffers) execute myselect_force_custom_plan(6);
explain (analyze,buffers) execute myselect_force_custom_plan(13);

