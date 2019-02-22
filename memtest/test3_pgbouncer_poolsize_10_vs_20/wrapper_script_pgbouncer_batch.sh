uptime
pgbench -h localhost -p 6432 -d pgbbench -U bench1 -c 30 -j 30 -T 300 -f custom_bench_nowait.sql &
for i in {1..10};do uptime;lsof | grep postgres | wc -l;sleep 5;done
