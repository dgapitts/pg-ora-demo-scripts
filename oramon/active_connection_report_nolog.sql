-- Monitoring Oracle active sessions (status <> 'INACTIVE') is a bit like:
--
-- * Postgres Active pg_stat_activity view (one major difference is that in pg we can distinguish between Idle and Idle in Transaction)
-- * MySQL SHOW PROCESSLIST (which shows which MySQL threads are running) ... tbc - my MySQL knowledge is more sketchy ;)
--
-- In v$session, we can see which which sessions are ACTIVE (i.e. typically are processing data, waiting on IO or locks), and matching this to v$process we can see extra details like PGA usage and the client_osuser:

column timestamp format a20
column date_time new_value today_var
select to_char(sysdate,'yyyy-mm-dd.HH24-MI') date_time from dual;
set linesize 150
column sess_key format a15
column last_work_date_time format a25
column client_osuser format a18
column spid format a10
column PGA_KB form 99999999
set pagesize 200
set linesize 160

select a.sid ||','|| a.serial# sess_key,  a.sql_id, a.prev_sql_id, last_call_et, 
to_char(sysdate-(last_call_et/(60*60*24)),'YYYY-MM-DD hh24:mi:ss') last_work_date_time, 
a.USERNAME, substr(machine,1,9) ||' '|| osuser client_osuser, b.spid,round(PGA_ALLOC_MEM/1024) as PGA_KB, 
status from gv$session a, gv$process b where a.paddr=b.addr and a.INST_ID=b.INST_ID and b.BACKGROUND IS NULL
and status <> 'INACTIVE' order by last_call_et desc;
exit
