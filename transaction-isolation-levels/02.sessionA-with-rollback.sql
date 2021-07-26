-- based off https://www.cockroachlabs.com/docs/stable/demo-serializable.html

BEGIN;

SELECT day, count(*) AS doctors_on_call FROM schedules
  WHERE on_call = true
  GROUP BY day
  ORDER BY day;


SELECT count(*) FROM schedules
  WHERE on_call = true
  AND day = '2018-10-05'
  AND doctor_id != 1;

-- pause for parallel session2 to start 
select now(), pg_sleep(10);

UPDATE schedules SET on_call = false
  WHERE day = '2018-10-05'
  AND doctor_id = 1;


SELECT day, count(*) AS doctors_on_call FROM schedules
  WHERE on_call = true
  GROUP BY day
  ORDER BY day;

rollback;  
