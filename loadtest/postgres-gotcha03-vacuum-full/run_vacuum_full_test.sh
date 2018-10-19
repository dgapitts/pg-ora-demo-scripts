
#echo 'setup generic pgbench data ... lots of insert'
pgbench -i -s 50  -n -h localhost -p 5432 -U bench1  -d bench1

echo 'start running a basic load test with a mixture of SELECT/UPDATE/DELETE/INSERT statements'
pgbench -c 32 -n -T 30  --username=bench1  -d bench1 &

sleep 15

echo 'after 15 seconds kick off VACUUM FULL'
psql -U bench1 -f demo_vacuum_full.sql
