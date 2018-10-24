SELECT *
FROM generate_series(1, 10) AS f(x);

SELECT x, SUM(x) OVER ()
FROM generate_series(1, 10) AS f(x);

SELECT x, COUNT(x) OVER (), SUM(x) OVER ()
FROM generate_series(1, 10) AS f(x);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS ();

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS UNBOUNDED PRECEDING);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN
             CURRENT ROW AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN 
             CURRENT ROW AND UNBOUNDED FOLLOWING);

SELECT x, COUNT(*) OVER w, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN
             1 PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN
             CURRENT ROW AND 1 FOLLOWING);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ROWS BETWEEN
             3 PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ORDER BY x);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ORDER BY x RANGE BETWEEN 
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_series(1, 10) AS f(x)
WINDOW w AS (ORDER BY x RANGE CURRENT ROW);

CREATE TABLE generate_1_to_5_x2 AS
        SELECT ceil(x/2.0) AS x
        FROM generate_series(1, 10) AS f(x);

SELECT * FROM generate_1_to_5_x2;

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS ();

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x ROWS BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x RANGE CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x ROWS CURRENT ROW);

SELECT x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x);

SELECT int4(x >= 3), x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3);

SELECT int4(x >= 3), x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3 ORDER BY x);

SELECT int4(x >= 3), x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3 ORDER BY x RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT int4(x >= 3), x, COUNT(x) OVER w, SUM(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3 ORDER BY x ROWS BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, ROW_NUMBER() OVER w
FROM generate_1_to_5_x2
WINDOW w AS ();

SELECT x, LAG(x, 1) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, LAG(x, 2) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, LAG(x, 2) OVER w, LEAD(x, 2) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, FIRST_VALUE(x) OVER w, LAST_VALUE(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, FIRST_VALUE(x) OVER w, LAST_VALUE(x) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x ROWS BETWEEN
             UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

SELECT x, NTH_VALUE(x, 3) OVER w, NTH_VALUE(x, 7) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, NTH_VALUE(x, 3) OVER w, NTH_VALUE(x, 7) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, NTH_VALUE(x, 3) OVER w, NTH_VALUE(x, 7) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x ROWS BETWEEN
             UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

SELECT x, RANK() OVER w, DENSE_RANK() OVER w
FROM generate_1_to_5_x2
WINDOW w AS ();

SELECT x, RANK() OVER w, DENSE_RANK() OVER w
FROM generate_1_to_5_x2
WINDOW w AS (RANGE BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, RANK() OVER w, DENSE_RANK() OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ROWS BETWEEN
             UNBOUNDED PRECEDING AND CURRENT ROW);

SELECT x, RANK() OVER w, DENSE_RANK() OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT x, (PERCENT_RANK() OVER w)::numeric(10, 2),
       (CUME_DIST() OVER w)::numeric(10, 2), NTILE(3) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (ORDER BY x);

SELECT int4(x >= 3), x, RANK() OVER w, DENSE_RANK() OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3 ORDER BY x)
ORDER BY 1,2;

SELECT int4(x >= 3), x, (PERCENT_RANK() OVER w)::numeric(10,2),
       (CUME_DIST() OVER w)::numeric(10,2), NTILE(3) OVER w
FROM generate_1_to_5_x2
WINDOW w AS (PARTITION BY x >= 3 ORDER BY x)
ORDER BY 1,2;

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

SELECT * FROM emp ORDER BY id;

SELECT COUNT(*), SUM(salary),
       round(AVG(salary), 2) AS avg
FROM emp;

SELECT department, COUNT(*), SUM(salary),
       round(AVG(salary), 2) AS avg
FROM emp
GROUP BY department
ORDER BY department;

SELECT department, COUNT(*), SUM(salary),
       round(AVG(salary), 2) AS avg
FROM emp
GROUP BY ROLLUP(department)
ORDER BY department;

SELECT name, salary
FROM emp
ORDER BY salary DESC;

SELECT name, salary, SUM(salary) OVER ()
FROM emp
ORDER BY salary DESC;

SELECT name, salary, 
       round(salary / SUM(salary) OVER () * 100, 2) AS pct
FROM emp
ORDER BY salary DESC;

SELECT name, salary,
       SUM(salary) OVER (ORDER BY salary DESC ROWS BETWEEN
			 UNBOUNDED PRECEDING AND CURRENT ROW)
FROM emp
ORDER BY salary DESC;

SELECT name, salary,
       round(AVG(salary) OVER (), 2) AS avg
FROM emp
ORDER BY salary DESC;

SELECT name, salary,
       round(AVG(salary) OVER (), 2) AS avg,
       round(salary - AVG(salary) OVER (), 2) AS diff_avg
FROM emp
ORDER BY salary DESC;


SELECT

SELECT name, salary,
       round(AVG(salary) OVER (), 2) AS avg,
       round(salary - AVG(salary) OVER (), 2) AS diff_avg
FROM emp
ORDER BY salary DESC;



SELECT name, salary,
       salary - LEAD(salary, 1) OVER 
                (ORDER BY salary DESC) AS diff_next
FROM emp
ORDER BY salary DESC;

SELECT name, salary,
       salary - LAST_VALUE(salary) OVER w AS more,
       round((salary - LAST_VALUE(salary) OVER w) / 
        LAST_VALUE(salary) OVER w * 100) AS pct_more
FROM emp
WINDOW w AS (ORDER BY salary DESC ROWS BETWEEN
             UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
ORDER BY salary DESC;

SELECT name, salary, RANK() OVER s, DENSE_RANK() OVER s
FROM emp
WINDOW s AS (ORDER BY salary DESC)
ORDER BY salary DESC;

SELECT name, department, salary,
       round(AVG(salary) OVER 
             (PARTITION BY department), 2) AS avg,
       round(salary - AVG(salary) OVER 
             (PARTITION BY department), 2) AS diff_avg
FROM emp
ORDER BY department, salary DESC;

SELECT name, department, salary,
       round(AVG(salary) OVER d, 2) AS avg,
       round(salary - AVG(salary) OVER d, 2) AS diff_avg
FROM emp
WINDOW d AS (PARTITION BY department)
ORDER BY department, salary DESC;

SELECT name, department, salary,
       salary - LEAD(salary, 1) OVER
       (PARTITION BY department
        ORDER BY salary DESC) AS diff_next
FROM emp
ORDER BY department, salary DESC;

SELECT name, department, salary, RANK() OVER s AS dept_rank,
       RANK() OVER (ORDER BY salary DESC) AS global_rank
FROM emp
WINDOW s AS (PARTITION BY department ORDER BY salary DESC)
ORDER BY department, salary DESC;

