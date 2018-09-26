# pg-scripts overview

This pg-scripts project/repro is for basic postgres  monitoring, simple load tests, interesting Postgres DBA edge cases and other demo exercises.

note:
* each subfolder has it own README.md with setup instructions and details of varioud perf/monitoring issues
* the dgapitts/vagrant-postgres9.6 can be used to quickly build a postgres-on-linux VM (I will work on a quick RDS/EC2 setup soon)

# pg-scripts details 

Already covered
* Rewriting this query with a NOT EXIST clause instead of NOT IN (Postgres specific gotcha)
* UNION vs UNION ALL (classic developer gotcha and similar perf issues on Postgres vs Oracle)

To Do
* Extreme Postgres Dead Row around Idle in Transaction
* Using CTE to get around Postgres hinting limitations
* Issues with postgres blocking and waiting scripts i.e. https://wiki.postgresql.org/wiki/Lock_Monitoring

Reference:
* "dgapitts/notes for my pg-scripts repro developement and tests" https://gist.github.com/dgapitts/1ca7e2eb4dfa475b1ffe1786277f7159
* "dgapitts/vagrant-postgres9.6"  https://github.com/dgapitts/vagrant-postgres9.6
