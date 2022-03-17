## random_json from ryanbooz's FOSDEM 2022 presenation


When I first tested this function:

```
[pg13centos7:vagrant:~] # cat random_json.sql
-- https://github.com/ryanbooz/Presentations/
-- Presentations_FOSDEM_part_1_and_2.sql at master · ryanbooz_Presentations
/*
 * Create the random function
 *
 * If no values are passed in, it will contain three objects
 * with values between 0 and 10
 *
 */
CREATE OR REPLACE FUNCTION random_json(keys TEXT[]='{"a","b","c"}',min_val NUMERIC = 0, max_val NUMERIC = 10)
   RETURNS JSON AS
$$
DECLARE
	random_val NUMERIC  = floor(random() * (max_val-min_val) + min_val)::INTEGER;
	random_json JSON = NULL;
BEGIN
	-- again, this adds some randomness into the results. Remove or modify if this
	-- isn't useful for your situation
	if(random_val % 5) > 1 then
		SELECT * INTO random_json FROM (
			SELECT json_object_agg(key, random_between(min_val,max_val)) as json_data
	    		FROM unnest(keys) as u(key)
		) json_val;
	END IF;
	RETURN random_json;
END
$$ LANGUAGE 'plpgsql';
```

I seemed to be getting some strange/buggy results

```
[pg13centos7:vagrant:~] # psql -f random_json.sql
CREATE FUNCTION
[pg13centos7:vagrant:~] # psql -f random_json.sql;psql -c "select random_json()"
CREATE FUNCTION
 random_json
-------------

(1 row)

[pg13centos7:vagrant:~] # psql -f random_json.sql;psql -c "select random_json()"
CREATE FUNCTION
 random_json
-------------

(1 row)
```

There is a function within the script so that randomly, you get blank's?

```
[pg13centos7:vagrant:~] # psql -c "select device_id, random_json() FROM generate_series(1,5) device_id;"
 device_id |          random_json
-----------+-------------------------------
         1 |
         2 |
         3 | { "a" : 8, "b" : 2, "c" : 4 }
         4 | { "a" : 5, "b" : 8, "c" : 6 }
         5 | { "a" : 7, "b" : 2, "c" : 9 }
(5 rows)

[pg13centos7:vagrant:~] # psql -c "select device_id, random_json() FROM generate_series(1,7) device_id;"
 device_id |          random_json
-----------+-------------------------------
         1 | { "a" : 7, "b" : 0, "c" : 3 }
         2 |
         3 |
         4 | { "a" : 7, "b" : 9, "c" : 4 }
         5 |
         6 | { "a" : 5, "b" : 8, "c" : 9 }
         7 | { "a" : 6, "b" : 7, "c" : 7 }
(7 rows)
```



So I tweaked the script to reduce the amount of blanks

```
[pg13centos7:vagrant:~] # diff random_json.sql random_json_orig.sql
13d12
<  * using `random_val % 20` ... one in twenty is blank
24c23
< 	if(random_val % 20) > 1 then
---
> 	if(random_val % 5) > 1 then

```

NB Actually I thought I was reducing the null from 1/5 (20%) to 1/20 (5%) but testing it is more like from 40% down to 10%

```
[pg13centos7:vagrant:~] # psql -c "select i, (i % 5) > 1  from generate_series(0,20) as i;"
 i  | ?column?
----+----------
  0 | f
  1 | f
  2 | t
  3 | t
  4 | t
  5 | f
  6 | f
  7 | t
  8 | t
  9 | t
 10 | f
 11 | f
 12 | t
 13 | t
 14 | t
 15 | f
 16 | f
 17 | t
 18 | t
 19 | t
 20 | f
(21 rows)

[pg13centos7:vagrant:~] # psql -c "select i, (i % 20) > 1  from generate_series(0,20) as i;"
 i  | ?column?
----+----------
  0 | f
  1 | f
  2 | t
  3 | t
  4 | t
  5 | t
  6 | t
  7 | t
  8 | t
  9 | t
 10 | t
 11 | t
 12 | t
 13 | t
 14 | t
 15 | t
 16 | t
 17 | t
 18 | t
 19 | t
 20 | f
(21 rows)

```






