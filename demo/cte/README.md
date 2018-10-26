## Overview

The following cte.sql is from Bruce Momjian's excellent CTE presentation, 
* https://momjian.us/main/writings/pgsql/cte.pdf 
* http://dailytechvideo.com/bruce-momjian-programming-sql-way-common-table-expressions/

## primefactors example - pure geeky maths example

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

## Hierarchical data - classic Employee / Manager relationship - more practical example

```
drop table emp;

CREATE TABLE emp (
    id integer,
    name TEXT NOT NULL,
    department TEXT, 
    salary NUMERIC(10, 2),
    manager integer
);

INSERT INTO emp (id,name, department, salary,manager) VALUES
        (1,'Jane','MD',8400,1),
        (2,'James', 'Shipping', 6600,1),
        (3,'Andy', 'Shipping', 5400,2),
        (4,'Tracy', 'Shipping', 4800,2),
        (5,'Mike', 'Marketing', 7100,1),
        (6,'Betty', 'Marketing', 6300,5),
        (7,'Sandy', 'Sales', 5400,1),
        (8,'Carol', 'Sales', 4600,7),
        (9,'Bob1', 'Marketing', 6300,6),
        (10,'Bob12', 'Marketing', 6300,6),
        (11,'Bob112', 'Marketing', 6300,6),
        (12,'Bob1112', 'Marketing', 6300,6);
```

retreiving all employee's under Mike from Marketing (emp.id=5)

```
bench1=> WITH RECURSIVE manager (id) AS (
        SELECT 5
        UNION
        SELECT emp.id
        FROM manager JOIN emp ON (manager.id = emp.manager)
)
SELECT * FROM manager;
 id
----
  5
  6
  9
 10
 11
 12
(6 rows)
```

and wrapping this into a SQL Function 


```
CREATE OR REPLACE FUNCTION reports (integer) RETURNS table (f1 int)
AS $$
WITH RECURSIVE manager (id) AS (
    SELECT $1
    UNION
    SELECT emp.id
    FROM manager JOIN emp ON (manager.id = emp.manager)
)
SELECT * FROM manager;
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;
```

and now we can see all the staff under Mike from Marketing (emp.id=5)

```
bench1=> select reports(5);
 reports
---------
       5
       6
       9
      10
      11
      12
(6 rows)
```

and the staff under James from Shipping (emp.id=2)

```
bench1=> select reports(2);
 reports
---------
       2
       3
       4
(3 rows)
```

