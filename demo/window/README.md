## Overview

The following window.sql is from Bruce Momjian's excellent windows presentation,
* https://momjian.us/main/writings/pgsql/windows.pdf
* https://www.youtube.com/watch?v=hWorm0m-D9U

Below I've highlighted a few key points from the pgconf.eu 2018 training session

## Defining your FRAME i.e. RANGE or ROWS

The FRAME for the CTE can be RANGE or ROWS

>  "You can redefine the frame by adding a suitable frame specification (RANGE or ROWS) to the OVER clause"
>  https://www.postgresql.org/docs/10/static/functions-window.html


Note RANGE is the default () which as Bruce points can be baffling when you start.

Probably easiest way to under FRAMEs is by examples, which is done very nicely in the windows.sql file and I've highlighted a few examples which I connected partiucularly 


## Simple examples with "ROWS BETWEEN 2 PRECEDING AND CURRENT ROW"


Comparison to previous row(s) is something which comes up from to time to time

The "ROWS BETWEEN 2 PRECEDING AND CURRENT ROW"
```
SELECT x, COUNT(*) OVER w, COUNT(x) OVER w, SUM(x) OVER w, AVG(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW);

```   

and the output here speaks for itself i.e. no surprises

```   
 x  | count | count | sum |          avg
----+-------+-------+-----+------------------------
  1 |     1 |     1 |   1 | 1.00000000000000000000
  2 |     2 |     2 |   3 |     1.5000000000000000
  3 |     3 |     3 |   6 |     2.0000000000000000
  4 |     3 |     3 |   9 |     3.0000000000000000
  5 |     3 |     3 |  12 |     4.0000000000000000
  6 |     3 |     3 |  15 |     5.0000000000000000
  7 |     3 |     3 |  18 |     6.0000000000000000
  8 |     3 |     3 |  21 |     7.0000000000000000
  9 |     3 |     3 |  24 |     8.0000000000000000
 10 |     3 |     3 |  27 |     9.0000000000000000
(10 rows)
```  

although one surprise/gotcha when we try to round over an aggregate function i.e. round is not a window function nor an aggregate function 

```
bench1=> SELECT x, COUNT(*) OVER w, COUNT(x) OVER w, SUM(x) OVER w, round(AVG(x),2) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW);
ERROR:  OVER specified, but round is not a window function nor an aggregate function
LINE 1: ... COUNT(*) OVER w, COUNT(x) OVER w, SUM(x) OVER w, round(AVG(...
```

and 

``` 
SELECT windowFunction.x, round(windowFunction.avg, 2) as aver_2dp FROM
( 
  SELECT x, AVG(x) OVER w
  FROM generate_series(1, 10) AS f(x) WINDOW w AS (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
) windowFunction;


 x  | aver_2dp
----+----------
  1 |     1.00
  2 |     1.50
  3 |     2.00
  4 |     3.00
  5 |     4.00
  6 |     5.00
  7 |     6.00
  8 |     7.00
  9 |     8.00
 10 |     9.00
(10 rows)

```


## Optimizer question 

Given the following simple test dataset

```
drop table emp;

CREATE TABLE emp (
    id SERIAL,
    name TEXT NOT NULL,
    department TEXT, 
    salary NUMERIC(10, 2)
);

INSERT INTO emp (name, department, salary) VALUES
        ('Andy', 'Shipping', 5400),
        ('Betty', 'Marketing', 6300),
        ('Tracy', 'Shipping', 4800),
        ('Mike', 'Marketing', 7100),
        ('Sandy', 'Sales', 5400),
        ('James', 'Shipping', 6600),
        ('Carol', 'Sales', 4600);
```

and then running the following 

```
bench1=> explain (analyze, buffers) SELECT COUNT(*), SUM(salary) FROM emp;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Aggregate  (cost=20.80..20.81 rows=1 width=40) (actual time=0.020..0.020 rows=1 loops=1)
   Buffers: shared hit=1
   ->  Seq Scan on emp  (cost=0.00..17.20 rows=720 width=16) (actual time=0.008..0.009 rows=7 loops=1)
         Buffers: shared hit=1
 Planning time: 0.038 ms
 Execution time: 0.047 ms
(6 rows)
```

the base cost (i.e. single "Seq Scan on emp") is the same:

```
bench1=> explain (analyze, buffers) SELECT COUNT(*), SUM(salary), round(AVG(salary), 2) AS avg FROM emp;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Aggregate  (cost=22.60..22.62 rows=1 width=72) (actual time=0.024..0.024 rows=1 loops=1)
   Buffers: shared hit=1
   ->  Seq Scan on emp  (cost=0.00..17.20 rows=720 width=16) (actual time=0.008..0.012 rows=7 loops=1)
         Buffers: shared hit=1
 Planning time: 0.048 ms
 Execution time: 0.069 ms
(6 rows)
```
