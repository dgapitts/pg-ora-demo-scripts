CREATE OR REPLACE FUNCTION primefactors_volatile (integer) RETURNS table (f1 int)
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
VOLATILE 
RETURNS NULL ON NULL INPUT;

select primefactors_volatile(7);
select primefactors_volatile(9);
select primefactors_volatile(66);
