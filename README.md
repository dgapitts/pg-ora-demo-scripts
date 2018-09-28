# pg-ora-demo-scripts overview

This pg-ora-demo-scripts project/repro is for basic postgres monitoring, simple load tests, interesting Postgres DBA edge cases and other demo exercises. It is especially aimed at Oracle DBA with comparisons to how Oracle handles such edge cases and some gotchas around migrating/moving from Postgres to Oracle.

note:
* each subfolder has it own README.md with setup instructions and details of varioud perf/monitoring issues
* the dgapitts/vagrant-postgres9.6 can be used to quickly build a postgres-on-linux VM 
* I will also work on a simple RDS/EC2 setup instructions, so you can run these tests in the AWS Cloud 

# pg-ora-demo-scripts details

## Already covered
* Rewriting this query with a NOT EXIST clause instead of NOT IN (Postgres specific gotcha and costs grow exponentially - demos with scale factors 1,2,3,5,10 and 20)
* UNION vs UNION ALL this a classic developer gotcha and similar perf issues on BOTH Postgres and Oracle, but watchout for minor manual pg-2-ora SQL conversions e.g. 'existence checks' with LIMIT=1 vs ROWNUM<2 and bracketing

## To Do
* Extreme Postgres Dead Row around Idle in Transaction
* Using CTE to get around Postgres hinting limitations (possibly with DBLinks) ?
* Issues with postgres blocking and waiting scripts i.e. https://wiki.postgresql.org/wiki/Lock_Monitoring (latest version of this pages is looking good)
* pgsql functions STABLE or VOLATILE (default) ?
