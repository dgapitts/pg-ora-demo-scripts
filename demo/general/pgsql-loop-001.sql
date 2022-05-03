-- https://www.postgresqltutorial.com/plpgsql-for-loop/
do $$
begin
   for counter in 1..5 loop
	raise notice 'counter: %', counter;
   end loop;
end; $$
