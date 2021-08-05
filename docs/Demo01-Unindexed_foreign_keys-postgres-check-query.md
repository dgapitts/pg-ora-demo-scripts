## Demo01 Unindexed_foreign_keys postgres check query

This script is a slightly cut down version https://wiki.postgresql.org/wiki/Unindexed_foreign_keys (which wraps this logic in a function, which maybe a good idea but can also be awkward in some circumstances)

```
~/projects/pg-ora-demo-scripts $ cat pgmon/unindex_foreign_key.sql
-- https://wiki.postgresql.org/wiki/Unindexed_foreign_keys

    SELECT
        pg_catalog.format('%I.%I', n1.nspname, c1.relname)  AS referencing_tbl,
        pg_catalog.quote_ident(a1.attname) AS referencing_column,
        t.conname AS existing_fk_on_referencing_tbl,
        pg_catalog.format('%I.%I', n2.nspname, c2.relname) AS referenced_tbl,
        pg_catalog.quote_ident(a2.attname) AS referenced_column,
        pg_relation_size( pg_catalog.format('%I.%I', n1.nspname, c1.relname) ) AS referencing_tbl_bytes,
        pg_relation_size( pg_catalog.format('%I.%I', n2.nspname, c2.relname) ) AS referenced_tbl_bytes,
        pg_catalog.format($$CREATE INDEX ON %I.%I(%I);$$, n1.nspname, c1.relname, a1.attname) AS suggestion
    FROM pg_catalog.pg_constraint t
    JOIN pg_catalog.pg_attribute  a1 ON a1.attrelid = t.conrelid AND a1.attnum = t.conkey[1]
    JOIN pg_catalog.pg_class      c1 ON c1.oid = t.conrelid
    JOIN pg_catalog.pg_namespace  n1 ON n1.oid = c1.relnamespace
    JOIN pg_catalog.pg_class      c2 ON c2.oid = t.confrelid
    JOIN pg_catalog.pg_namespace  n2 ON n2.oid = c2.relnamespace
    JOIN pg_catalog.pg_attribute  a2 ON a2.attrelid = t.confrelid AND a2.attnum = t.confkey[1]
    WHERE t.contype = 'f'
    AND NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_index i
        WHERE i.indrelid = t.conrelid
        AND i.indkey[0] = t.conkey[1]
    );
```


Working with the following simple schema 



```
~/projects/pg-ora-demo-scripts $ psql
psql (13.3)

dave=# \d
         List of relations
 Schema |   Name    | Type  | Owner
--------+-----------+-------+-------
 public | doctors   | table | dave
 public | schedules | table | dave
(2 rows)

dave=# \d doctors
              Table "public.doctors"
 Column |  Type   | Collation | Nullable | Default
--------+---------+-----------+----------+---------
 id     | integer |           | not null |
 name   | text    |           |          |
Indexes:
    "doctors_pkey" PRIMARY KEY, btree (id)
Referenced by:
    TABLE "schedules" CONSTRAINT "schedules_doctor_id_fkey" FOREIGN KEY (doctor_id) REFERENCES doctors(id)

dave=# \d schedules
               Table "public.schedules"
  Column   |  Type   | Collation | Nullable | Default
-----------+---------+-----------+----------+---------
 day       | date    |           | not null |
 doctor_id | integer |           | not null |
 on_call   | boolean |           |          |
Indexes:
    "schedules_pkey" PRIMARY KEY, btree (day, doctor_id)
Foreign-key constraints:
    "schedules_doctor_id_fkey" FOREIGN KEY (doctor_id) REFERENCES doctors(id)
```
and 
```
~/projects/pg-ora-demo-scripts $ psql -f pgmon/unindex_foreign_key.sql
 referencing_tbl  | referencing_column | existing_fk_on_referencing_tbl | referenced_tbl | referenced_column | referencing_tbl_bytes | referenced_tbl_bytes |                  suggestion
------------------+--------------------+--------------------------------+----------------+-------------------+-----------------------+----------------------+----------------------------------------------
 public.schedules | doctor_id          | schedules_doctor_id_fkey       | public.doctors | id                |                  8192 |                 8192 | CREATE INDEX ON public.schedules(doctor_id);
(1 row)
```
and this is probably nicer in the '\x' view:
```
dave=# \i pgmon/unindex_foreign_key.sql
-[ RECORD 1 ]------------------+---------------------------------------------
referencing_tbl                | public.schedules
referencing_column             | doctor_id
existing_fk_on_referencing_tbl | schedules_doctor_id_fkey
referenced_tbl                 | public.doctors
referenced_column              | id
referencing_tbl_bytes          | 8192
referenced_tbl_bytes           | 8192
suggestion                     | CREATE INDEX ON public.schedules(doctor_id);
```