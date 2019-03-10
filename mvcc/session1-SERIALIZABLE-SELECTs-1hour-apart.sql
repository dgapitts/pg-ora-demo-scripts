SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
select count(*) from test_mvcc;
SELECT pg_sleep(3600);
select count(*) from test_mvcc;
