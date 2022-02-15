drop table t1_90;
CREATE TABLE t1_90 (
   v1  int,
   f1  varchar(30) default 'aaa123',
   f2  varchar(30) default 'baa123',
   f3  varchar(30) default 'caa123',
   f4  varchar(30) default 'daa123',
   f5  varchar(30) default 'eaa123',
   f6  varchar(30) default 'faa123',
   f7  varchar(30) default 'gaa123',
   f8  varchar(30) default 'haa123',
   f9  varchar(30) default 'iaa123'
) WITH (autovacuum_enabled = off, fillfactor=90);
create index concurrently t1_f1 on t1(f1);
create index concurrently t1_f2 on t1(f2);
INSERT INTO t1_90 (v1)  SELECT * FROM generate_series(0, 100) AS n;
SELECT ctid, v1, f1 from t1_90;
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
 update t1_90 set f3 = 'v2' where v1 = 2;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
update t1_90 set f3 = 'v2' where v1 = 3;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
SELECT ctid, v1, f1 from t1_90 order by v1 limit 10;
SELECT ctid, v1, f1, f3 from t1_90 order by v1 limit 10;
update t1_90 set f1 = 'v2' where v1 = 4;
SELECT ctid, v1, f1, f3 from t1_90 order by v1 limit 10;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_90';
