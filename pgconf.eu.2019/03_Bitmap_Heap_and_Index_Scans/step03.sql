\timing on
 explain analyze select * from t_test where id < 1000 or salary = 10;
\h explain
 explain analyze verbose select * from t_test where id < 1000 or salary = 10;
create index t_test_salary on t_test(salary);
 explain analyze verbose select * from t_test where id < 1000 or salary = 10;
 explain analyze verbose select * from t_test where id < 100 or salary = 10;
 explain analyze verbose select * from t_test where id < 10 or salary = 10;
\d t_test
\di+
