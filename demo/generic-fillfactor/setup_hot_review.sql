\timing on

CREATE TABLE t1 as SELECT id, random()*100000::int as val, md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as row_filler FROM generate_series (0,100) as id;

create unique index t1_id_uniq on t1(id);

create index t1_val on t1(val);

ALTER TABLE t1 SET (autovacuum_enabled = off);

\d+ t1
