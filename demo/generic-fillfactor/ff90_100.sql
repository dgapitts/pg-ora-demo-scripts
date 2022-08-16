set search_path=:vSchema;

show search_path;

CREATE TABLE ff90_100(
    id bigint ,
    key CHARACTER VARYING,
    pad1 text,
    pad2 text,
    CONSTRAINT key_uniq_con_ff90_100 UNIQUE (id,key)
) with (fillfactor = 90);


ALTER TABLE ONLY ff90_100 ADD CONSTRAINT ff90_100_pkey PRIMARY KEY (id) with (fillfactor = 100);

CREATE INDEX ff90_100_key ON ff90_100 USING btree (key) with (fillfactor = 100);
CREATE INDEX ff90_100_pad1 ON ff90_100 USING btree (pad1) with (fillfactor = 100);

insert into ff90_100 SELECT id, random()*100000::int as key, md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad1,  md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad2 FROM generate_series (0,1000000,10) as id;

analyze ff90_100;
\d+ ff90_100
