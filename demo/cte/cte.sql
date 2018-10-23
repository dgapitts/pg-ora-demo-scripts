
-- 000simple.sql
-- ----------------
WITH source AS (
	SELECT 1
)
SELECT * FROM source;

WITH source AS (
	SELECT 1 AS col1
)
SELECT * FROM source;

-- 012cols.sql
-- ----------------
WITH source (col1) AS (
	SELECT 1
)
SELECT * FROM source;

WITH source (col2) AS (
	SELECT 1 AS col1
)
SELECT col2 AS col3 FROM source;

WITH source AS (
	SELECT 1, 2
)
SELECT * FROM source;

-- 014union.sql
-- ----------------
SELECT 1 
UNION
SELECT 1;

SELECT 1 
UNION ALL 
SELECT 1;

-- 016multi_col.sql
-- ----------------
WITH source AS (
	SELECT 1, 2
),
     source2 AS (
	SELECT 3, 4
)
SELECT * FROM source
UNION ALL
SELECT * FROM source2;

-- 020query.sql
-- ----------------
WITH source AS (
	SELECT lanname, rolname
	FROM pg_language JOIN pg_roles ON lanowner = pg_roles.oid
)
SELECT * FROM source;

WITH source AS (
	SELECT lanname, rolname
	FROM pg_language JOIN pg_roles ON lanowner = pg_roles.oid
	ORDER BY lanname
)
SELECT * FROM source
UNION ALL
SELECT MIN(lanname), NULL
FROM source;

WITH class AS (
	SELECT oid, relname
	FROM pg_class
	WHERE relkind = 'r'
)
SELECT class.relname, attname
FROM pg_attribute, class
WHERE class.oid = attrelid
ORDER BY 1, 2
LIMIT 5;

-- 030recursive.sql
-- ----------------
WITH RECURSIVE source AS (
	SELECT 1 
)
SELECT * FROM source;

SET statement_timeout = '1s';

WITH RECURSIVE source AS (
	SELECT 1 
	UNION ALL 
	SELECT 1 FROM source
)
SELECT * FROM source;

WITH RECURSIVE source AS (
	SELECT 'Hello'
	UNION ALL 
	SELECT 'Hello' FROM source
)
SELECT * FROM source;

RESET statement_timeout;

WITH RECURSIVE source AS (
	SELECT 'Hello'
	UNION
	SELECT 'Hello' FROM source
)
SELECT * FROM source;

-- 052counter.sql
-- ----------------
WITH RECURSIVE source (counter) AS (
	-- seed value
	SELECT 1
	UNION ALL
	SELECT counter + 1
	FROM source 
	-- terminal condition
	WHERE counter < 10
)
SELECT * FROM source;

-- 054factorial.sql
-- ----------------
WITH RECURSIVE source (counter, product) AS (
	SELECT 1, 1
	UNION ALL
	SELECT counter + 1, product * (counter + 1)
	FROM source
	WHERE counter < 10
)
SELECT counter, product FROM source;

WITH RECURSIVE source (counter, product) AS (
	SELECT 1, 1
	UNION ALL
	SELECT counter + 1, product * (counter + 1)
	FROM source
	WHERE counter < 10
)
SELECT counter, product
FROM source
WHERE counter = 10;

-- 055string.sql
-- ----------------
WITH RECURSIVE source (str) AS (
	SELECT 'a'
	UNION ALL
	SELECT str || 'a'
	FROM source
	WHERE length(str) < 10
)
SELECT * FROM source;

WITH RECURSIVE source (str) AS (
	SELECT 'a'
	UNION ALL
	SELECT str || chr(ascii(substr(str, length(str))) + 1)
	FROM source
	WHERE length(str) < 10
)
SELECT * FROM source;

-- 060X.sql
-- ----------------
WITH RECURSIVE source (counter) AS (
        SELECT -10
        UNION ALL
        SELECT counter + 1
        FROM source

        WHERE counter < 10
)
SELECT 	repeat(' ', 5 - abs(counter) / 2) || 
	'X' || 
	repeat(' ', abs(counter)) || 
	'X' 
FROM source;

WITH RECURSIVE source (counter) AS (
        SELECT -10
        UNION ALL
        SELECT counter + 1
        FROM source

        WHERE counter < 10
)
SELECT 	counter, 
	repeat(' ', 5 - abs(counter) / 2) || 
	'X' || 
	repeat(' ', abs(counter)) || 
	'X'
FROM source;

-- 062O.sql
-- ----------------
WITH RECURSIVE source (counter) AS (
        SELECT -10
        UNION ALL
        SELECT counter + 1
        FROM source
        WHERE counter < 10
)
SELECT  repeat(' ', abs(counter)/2) ||
        'X' ||
        repeat(' ', 10 - abs(counter)) ||
        'X'
FROM source;

WITH RECURSIVE source (counter) AS (
        SELECT -10
        UNION ALL
        SELECT counter + 1
        FROM source
        WHERE counter < 10
)
SELECT  repeat(' ', int4(pow(counter, 2)/10)) ||
        'X' ||
        repeat(' ', 2 * (10 - int4(pow(counter, 2)/10))) ||
        'X'
FROM source;

WITH RECURSIVE source (counter) AS (
        SELECT -10
        UNION ALL
        SELECT counter + 1
        FROM source
        WHERE counter < 10
)
SELECT  repeat(' ', int4(pow(counter, 2)/5)) ||
        'X' ||
   repeat(' ', 2 * (20 - int4(pow(counter, 2)/5))) ||
        'X'
FROM source;

-- 070factors.sql
-- ----------------
WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2, 56, false
	UNION ALL
	SELECT
		CASE
			WHEN factor % counter = 0 THEN counter
			ELSE counter + 1
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
SELECT * FROM source;

-- factors only
WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2, 56, false
	UNION ALL
	SELECT
		CASE
			WHEN factor % counter = 0 THEN counter
			ELSE counter + 1
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
SELECT * FROM source WHERE is_factor;

WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2, 322434, false
	UNION ALL
	SELECT
		CASE
			WHEN factor % counter = 0 THEN counter
			ELSE counter + 1
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
SELECT * FROM source WHERE is_factor;

-- 074factors_optimized.sql
-- ----------------
WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2, 66, false
	UNION ALL
	SELECT
		CASE
			WHEN factor % counter = 0 THEN counter
			ELSE counter + 1
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
SELECT * FROM source;

WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2, 66, false
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
SELECT * FROM source;

WITH RECURSIVE source (counter, factor, is_factor) AS (
	SELECT 2,66, false
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
SELECT * FROM source WHERE is_factor;

-- 080setup.sql
-- ----------------
CREATE TEMPORARY TABLE part (parent_part_no INTEGER, part_no INTEGER);
INSERT INTO part VALUES (1, 11);
INSERT INTO part VALUES (1, 12);
INSERT INTO part VALUES (1, 13);
INSERT INTO part VALUES (2, 21);
INSERT INTO part VALUES (2, 22);
INSERT INTO part VALUES (2, 23);
INSERT INTO part VALUES (11, 101);
INSERT INTO part VALUES (13, 102);
INSERT INTO part VALUES (13, 103);
INSERT INTO part VALUES (22, 221);
INSERT INTO part VALUES (22, 222);
INSERT INTO part VALUES (23, 231);

-- 082explode.sql
-- ----------------
WITH RECURSIVE source (part_no) AS (
        SELECT 2
        UNION ALL
        SELECT part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
SELECT * FROM source;

-- 085dashes.sql
-- ----------------
WITH RECURSIVE source (level, part_no) AS (
        SELECT 0, 2
        UNION ALL
        SELECT level + 1, part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
SELECT '+' || repeat('-', level * 2) || part_no::text AS part_tree
FROM source;

-- 087dash_order.sql
-- ----------------
-- ASCII order
WITH RECURSIVE source (level, tree, part_no) AS (
        SELECT 0, '2', 2
        UNION ALL
        SELECT level + 1, tree || ' ' || part.part_no::text, part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
SELECT '+' || repeat('-', level * 2) || part_no::text AS part_tree, tree
FROM source
ORDER BY tree;

-- numeric order
WITH RECURSIVE source (level, tree, part_no) AS (
        SELECT 0, '{2}'::int[], 2
        UNION ALL
        SELECT level + 1, array_append(tree, part.part_no), part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
SELECT '+' || repeat('-', level * 2) || part_no::text AS part_tree, tree
FROM source
ORDER BY tree;

WITH RECURSIVE source (level, tree, part_no) AS (
        SELECT 0, '{2}'::int[], 2
        UNION ALL
        SELECT level + 1, array_append(tree, part.part_no), part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
SELECT *, '+' || repeat('-', level * 2) || part_no::text AS part_tree
FROM source
ORDER BY tree;

-- 090setup.sql
-- ----------------
CREATE TEMPORARY TABLE deptest (x1 INTEGER);

-- 092dependency.sql
-- ----------------
WITH RECURSIVE dep (classid, obj) AS (
	SELECT (SELECT oid FROM pg_class WHERE relname = 'pg_class'),
		oid 
	FROM pg_class
	WHERE relname = 'deptest'
	UNION ALL
	SELECT pg_depend.classid, objid
	FROM pg_depend JOIN dep ON (refobjid = dep.obj)
)
SELECT  (SELECT relname FROM pg_class WHERE oid = classid) AS class,
	(SELECT typname FROM pg_type WHERE oid = obj) AS type,
	(SELECT relname FROM pg_class WHERE oid = obj) AS class,
	(SELECT relkind FROM pg_class where oid = obj::regclass) AS kind,
	(SELECT adsrc FROM pg_attrdef WHERE oid = obj) AS attrdef,
	(SELECT conname FROM pg_constraint WHERE oid = obj) AS constraint
FROM dep
ORDER BY obj;

-- show only dependent objects, not the object itself
WITH RECURSIVE dep (classid, obj) AS (
	SELECT classid, objid
	FROM pg_depend JOIN pg_class ON (refobjid = pg_class.oid)
	WHERE relname = 'deptest'
	UNION ALL
	SELECT pg_depend.classid, objid
	FROM pg_depend JOIN dep ON (refobjid = dep.obj)
)
SELECT  (SELECT relname FROM pg_class WHERE oid = classid) AS class,
	(SELECT typname FROM pg_type WHERE oid = obj) AS type,
	(SELECT relname FROM pg_class WHERE oid = obj) AS class,
	(SELECT relkind FROM pg_class where oid = obj::regclass) AS kind,
	(SELECT adsrc FROM pg_attrdef WHERE oid = obj) AS attrdef,
	(SELECT conname FROM pg_constraint WHERE oid = obj) AS constraint
FROM dep
ORDER BY obj;

-- 094primary.sql
-- ----------------
ALTER TABLE deptest ADD PRIMARY KEY (x1);

WITH RECURSIVE dep (classid, obj) AS (
	SELECT (SELECT oid FROM pg_class WHERE relname = 'pg_class'),
		oid 
	FROM pg_class
	WHERE relname = 'deptest'
	UNION ALL
	SELECT pg_depend.classid, objid
	FROM pg_depend JOIN dep ON (refobjid = dep.obj)
)
SELECT  (SELECT relname FROM pg_class WHERE oid = classid) AS class,
	(SELECT typname FROM pg_type WHERE oid = obj) AS type,
	(SELECT relname FROM pg_class WHERE oid = obj) AS class,
	(SELECT relkind FROM pg_class where oid = obj::regclass) AS kind,
	(SELECT adsrc FROM pg_attrdef WHERE oid = obj) AS attrdef,
	(SELECT conname FROM pg_constraint WHERE oid = obj) AS constraint
FROM dep
ORDER BY obj;

-- 096add_col.sql
-- ----------------
ALTER TABLE deptest ADD COLUMN x2 SERIAL;

WITH RECURSIVE dep (classid, obj) AS (
	SELECT (SELECT oid FROM pg_class WHERE relname = 'pg_class'),
		oid 
	FROM pg_class
	WHERE relname = 'deptest'
	UNION ALL
	SELECT pg_depend.classid, objid
	FROM pg_depend JOIN dep ON (refobjid = dep.obj)
)
SELECT  (SELECT relname FROM pg_class WHERE oid = classid) AS class,
	(SELECT typname FROM pg_type WHERE oid = obj) AS type,
	(SELECT relname FROM pg_class WHERE oid = obj) AS class,
	(SELECT relkind FROM pg_class where oid = obj::regclass) AS kind,
	(SELECT adsrc FROM pg_attrdef WHERE oid = obj) AS attrdef,
	(SELECT conname FROM pg_constraint WHERE oid = obj) AS constraint
FROM dep
ORDER BY obj;

-- show dependency tree
WITH RECURSIVE dep (level, tree, classid, obj) AS (
	SELECT 0, array_append(null, oid)::oid[],
		(SELECT oid FROM pg_class WHERE relname = 'pg_class'),
		oid 
	FROM pg_class
	WHERE relname = 'deptest'
	UNION ALL
	SELECT level + 1, array_append(tree, objid),
		pg_depend.classid, objid
	FROM pg_depend JOIN dep ON (refobjid = dep.obj)
)
SELECT  tree,
	(SELECT relname FROM pg_class WHERE oid = classid) AS class,
	(SELECT typname FROM pg_type WHERE oid = obj) AS type,
	(SELECT relname FROM pg_class WHERE oid = obj) AS class,
	(SELECT relkind FROM pg_class where oid = obj::regclass) AS kind,
	(SELECT adsrc FROM pg_attrdef WHERE oid = obj) AS attrdef,
	(SELECT conname FROM pg_constraint WHERE oid = obj) AS constraint
FROM dep
ORDER BY tree, obj;

-- 100returning.sql
-- ----------------
CREATE TEMPORARY TABLE retdemo (x NUMERIC);

INSERT INTO retdemo VALUES (random()), (random()), (random()) RETURNING x;

WITH source AS (
	INSERT INTO retdemo VALUES (random()), (random()), (random()) RETURNING x
)
SELECT AVG(x) FROM source;

WITH source AS (
	DELETE FROM retdemo RETURNING x
)
SELECT MAX(x) FROM source;

-- 110delete.sql
-- ----------------
CREATE TEMPORARY TABLE retdemo2 (x NUMERIC);

INSERT INTO retdemo2 VALUES (random()), (random()), (random());

WITH source (average) AS (
	SELECT AVG(x) FROM retdemo2
)
DELETE FROM retdemo2 USING source 
WHERE retdemo2.x < source.average;

SELECT * FROM retdemo2;

-- 115delete.sql
-- ----------------
WITH RECURSIVE source (part_no) AS (
        SELECT 2
        UNION ALL
        SELECT part.part_no
        FROM source JOIN part ON (source.part_no = part.parent_part_no)
)
DELETE FROM part USING source WHERE source.part_no = part.part_no;

-- 120ret_del.sql
-- ----------------
CREATE TEMPORARY TABLE retdemo3 (x NUMERIC);

INSERT INTO retdemo3 VALUES (random()), (random()), (random());

WITH source (average) AS (
	SELECT AVG(x) FROM retdemo3
),
     source2 AS (
	DELETE FROM retdemo3 USING source 
	WHERE retdemo3.x < source.average
	RETURNING x
)
SELECT * FROM source2;

-- 125serial.sql
-- ----------------
CREATE TEMPORARY TABLE orders (order_id SERIAL, name text);
CREATE TEMPORARY TABLE items (order_id INTEGER, part_id SERIAL, name text);

WITH source (order_id) AS (
	INSERT INTO orders VALUES (DEFAULT, 'my order') RETURNING order_id
)
INSERT INTO items (order_id, name) SELECT order_id, 'my part' FROM source;

WITH source (order_id) AS (
	DELETE FROM orders WHERE name = 'my order' RETURNING order_id
)
DELETE FROM items USING source WHERE source.order_id = items.order_id;

-- 130log.sql
-- ----------------
CREATE TEMPORARY TABLE old_orders (order_id INTEGER);

WITH source (order_id) AS (
	DELETE FROM orders WHERE name = 'my order' RETURNING order_id
), source2 AS (
	DELETE FROM items USING source WHERE source.order_id = items.order_id
)
INSERT INTO old_orders SELECT order_id FROM source;

