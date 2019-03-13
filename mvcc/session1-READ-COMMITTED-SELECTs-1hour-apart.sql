begin;
select count(*) from test_mvcc;
SELECT pg_sleep(300);
select count(*) from test_mvcc;
end;
