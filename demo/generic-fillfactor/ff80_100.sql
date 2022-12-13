set search_path=:vSchema;

show search_path;

CREATE TABLE ff80_100(
    id bigint ,
    key CHARACTER VARYING,
    pad1 text,
    pad2 text,
    CONSTRAINT key_uniq_con_ff80_100 UNIQUE (id,key)
) with (fillfactor = 80);


ALTER TABLE ONLY ff80_100 ADD CONSTRAINT ff80_100_pkey PRIMARY KEY (id) with (fillfactor = 100);

CREATE INDEX ff80_100_key ON ff80_100 USING btree (key) with (fillfactor = 100);
CREATE INDEX ff80_100_pad1 ON ff80_100 USING btree (pad1) with (fillfactor = 100);

insert into ff80_100 SELECT id, random()*100000::int as key, md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad1,  md5(id::text)||md5(id::text)||md5(id::text)||md5(id::text) as pad2 FROM generate_series (0,1000000,10) as id;

analyze ff80_100;
\d+ ff80_100
