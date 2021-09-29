-- https://www.postgresqltutorial.com/plpgsql-for-loop/
do $$
declare
    counter record;
begin
   for counter in select generate_series(1, 6)
   loop
	raise notice 'counter: %', counter;
   end loop;
end; $$

