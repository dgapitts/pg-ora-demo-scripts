-- https://www.postgresqltutorial.com/plpgsql-for-loop/
do $$
declare
    counter record;
    current_time record;
begin
   for counter in select generate_series(1, 6)
   loop
      for current_time in select now(),pg_sleep(2)
      loop 
         raise notice '%', current_time;
      end loop;
   end loop;
end; $$

