-- https://www.cybertec-postgresql.com/en/index-your-foreign-key/

drop table if exists target cascade;
drop table if exists source cascade;


-- to make the plans look simpler
SET max_parallel_workers_per_gather = 0;
-- to speed up CREATE INDEX
SET maintenance_work_mem = '512MB';
 
CREATE TABLE target (
   t_id integer NOT NULL,
   t_name text NOT NULL
);
INSERT INTO target (t_id, t_name)
   SELECT i, 'target ' || i
   FROM generate_series(1, 500001) AS i;
 
ALTER TABLE target
   ADD PRIMARY KEY (t_id);
 
CREATE INDEX ON target (t_name);
 
/* set hint bits and collect statistics */
VACUUM (ANALYZE) target;
 
CREATE TABLE source (
   s_id integer NOT NULL,
   t_id integer NOT NULL,
   s_name text NOT NULL
);
INSERT INTO source (s_id, t_id, s_name)
   SELECT i, (i - 1) % 500000 + 1, 'source ' || i
   FROM generate_series(1, 1000000) AS i;
 
ALTER TABLE source
   ADD PRIMARY KEY (s_id);
 
ALTER TABLE source
   ADD FOREIGN KEY (t_id) REFERENCES target;
 
/* set hint bits and collect statistics */
VACUUM (ANALYZE) source;
