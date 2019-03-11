CREATE TABLE test_mvcc (id serial PRIMARY KEY, num integer);
insert into test_mvcc (select a, random() * 1000 from generate_series(0, 100000) a);
