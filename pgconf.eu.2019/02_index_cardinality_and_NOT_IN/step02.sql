explain analyze select count(*) from t_test where name = 'dave';
explain analyze select count(*) from t_test where name = 'dave2';
explain analyze select count(*) from t_test where name = 'dave';
create index t_test_name on t_test(name);
explain analyze select count(*) from t_test where name = 'dave';
\dt+
\di+
explain analyze select count(*) from t_test where name = 'dave';
explain analyze select count(*) from t_test where name = 'dave2';
create index t_test_name_excluding on t_test(name) where name not in ('dave','thomas');'
explain analyze select count(*) from t_test where name = 'dave2';
\di+
