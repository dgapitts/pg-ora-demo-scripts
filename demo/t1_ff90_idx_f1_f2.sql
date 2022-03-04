drop table t1_ff90_idx_f1_f2;
CREATE TABLE t1_ff90_idx_f1_f2 (
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
drop index concurrently t1_ff90_idx_f1_f2_1;
drop index concurrently t1_ff90_idx_f1_f2_2;
create index concurrently t1_ff90_idx_f1_f2_1 on t1_ff90_idx_f1_f2(f1);
create index concurrently t1_ff90_idx_f1_f2_2 on t1_ff90_idx_f1_f2(f2);
INSERT INTO t1_ff90_idx_f1_f2 (v1)  SELECT * FROM generate_series(0, 100) AS n;
SELECT ctid, v1, f1 from t1_ff90_idx_f1_f2;
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_ff90_idx_f1_f2';
explain (analyze,wal) update t1_ff90_idx_f1_f2 set f3 = 'v2' where v1 = 2;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_ff90_idx_f1_f2';
explain (analyze,wal)  update t1_ff90_idx_f1_f2 set f3 = 'v2' where v1 = 3;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_ff90_idx_f1_f2';
SELECT ctid, v1, f1, f3 from t1_ff90_idx_f1_f2 order by v1 limit 10;
explain (analyze,wal) update t1_ff90_idx_f1_f2 set f1 = 'v2' where v1 = 4;
SELECT ctid, v1, f1, f3 from t1_ff90_idx_f1_f2 order by v1 limit 10;
select pg_sleep(3);
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables where relname = 't1_ff90_idx_f1_f2';