## Overview

The following cte.sql is from Bruce Momjian's excellent CTE presentation, 
* https://momjian.us/main/writings/pgsql/cte.pdf 
* http://dailytechvideo.com/bruce-momjian-programming-sql-way-common-table-expressions/

One tweak I've made (with some help from Bruce himself at PgConf EU 2018 in Lisbon) is to include the primefactors as a sqlfunction (the origin has 66 hardcoded into the RECURSIVE SQL example:

```
[pg96centos7:postgres:~/pg-ora-demo-scripts/demo/cte] # cat  primefactors.sql
CREATE OR REPLACE FUNCTION primefactors (integer) RETURNS table (f1 int)
AS $$
WITH RECURSIVE source (counter, factor, is_factor) AS (
SELECT 2, $1, false
UNION ALL
SELECT
CASE
    WHEN factor % counter = 0 THEN counter
    -- is 'factor' prime?
    WHEN counter * counter > factor THEN factor
    -- now only odd numbers
    WHEN counter = 2 THEN 3
    ELSE counter + 2
    END,
CASE
    WHEN factor % counter = 0 THEN factor / counter
    ELSE factor
END,
CASE
    WHEN factor % counter = 0 THEN true
    ELSE false
END
FROM source
WHERE factor <> 1
)
SELECT counter FROM source WHERE is_factor = true
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

select primefactors(7);
select primefactors(9);
select primefactors(66);
```

and executing this:
```
[pg96centos7:postgres:~/pg-ora-demo-scripts/demo/cte] # psql -U bench1 -f primefactors.sql
CREATE FUNCTION
 primefactors
--------------
            7
(1 row)

 primefactors
--------------
            3
            3
(2 rows)

 primefactors
--------------
            2
            3
           11
(3 rows)
```

