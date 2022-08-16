set search_path=:vSchema;

--show search_path;

explain analyze insert into :vTable (id, key, pad1,  pad2) 
select id, key, pad1, pad2
from :vTable
WHERE mod(id, :vMod )=0
ORDER by id limit :vNumRows
on conflict (id, key)
do update set pad2 = :vTable.id::text;

