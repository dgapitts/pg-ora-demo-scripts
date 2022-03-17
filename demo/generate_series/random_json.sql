/*
 * Create the random function
 * 
 * If no values are passed in, it will contain three objects
 * with values between 0 and 10
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

