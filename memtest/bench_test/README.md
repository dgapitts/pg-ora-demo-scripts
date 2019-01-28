== How to run ==

I started with the extremely simple python script
```
~/projects/pg-ora-demo-scripts/memtest $ cat gen_sql.py
for i in range(10001):
    print "select * from tab"+str(i)+;"
    print "select now(), pg_sleep(2);"
```

and then generate you CREATE SQL statements via
```
~/projects/pg-ora-demo-scripts/memtest $ python gen_sql.py > custom_bench.sql
```