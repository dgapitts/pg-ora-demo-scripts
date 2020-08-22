drop table supplier;
\timing on
CREATE TABLE supplier (
	id SERIAL PRIMARY KEY, 
	created timestamp without time zone, 
	name  VARCHAR(100) NOT NULL default ('[0:3]={Akbar,Ashwin,Faruk,Sahul}'::text[])[floor(random()*4)], 
	n5 numeric default round(random()*5),
	n10 numeric default round(random()*10),
	n100 numeric default round(random()*100),
	n1000 numeric default round(random()*1000),
	n10000 numeric default round(random()*10000),
	n100000 numeric default round(random()*100000),
	a10 varchar default (('A'::varchar)||(round(random()*10)::varchar)),
	a1000 text default (('A'::varchar)||(round(random()*1000)::varchar)),
	a100000 varchar default (('A'::varchar)||(round(random()*100000)::varchar)),
	a10000000 text default (('A'::varchar)||(round(random()*10000000)::varchar))
);

insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));
insert into supplier(created)  values (now() - random() * (timestamp '1980-01-01 00:00:00' - timestamp '1970-01-01 00:00:00'));


insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);
insert into supplier(created) (select created from supplier);

