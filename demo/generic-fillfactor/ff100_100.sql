set search_path=:vSchema;

show search_path;

CREATE TABLE ff100_100(
    id bigint ,
    key CHARACTER VARYING,
    pad1 text,
    pad2 text,
    CONSTRAINT key_uniq_con_ff100_100 UNIQUE (id,key)
) with (fillfactor = 100);


ALTER TABLE ONLY ff100_100 ADD CONSTRAINT ff100_100_pkey PRIMARY KEY (id) with (fillfactor = 100);

CREATE INDEX ff100_100_key ON ff100_100 USING btree (key) with (fillfactor = 100);
CREATE INDEX ff100_100_pad1 ON ff100_100 USING btree (pad1) with (fillfactor = 100);

insert into ff100_100 SELECT id, random()*100000::int as key, md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad1,  md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad2 FROM generate_series (0,1000000,10) as id;

analyze ff100_100;
\d+ ff100_100
