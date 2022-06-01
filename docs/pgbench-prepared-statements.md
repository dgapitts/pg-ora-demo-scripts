## Sumary - prepared statements can be a lot faster but issues around partitioning 

Postgres prepared statements work well for simple queries and in the pgbench test with a regular table we see roughly double the number of TPS.

However following this postgres blog post["Postgres: on performance of prepared statements with partitioning"]](https://amitlan.com/2022/05/16/param-query-partition-woes.html) (and associate ongoing patch request), prepared statements dont work that well with partitioning. This is reflected in the 10 and 100 partition based tests below, although not as dramatically?


## regular table (no partitions) 

### setup

```
[pg13-db1:postgres:~] # pgbench -i -s 5
dropping old tables...
creating tables...
generating data (client-side)...
500000 of 500000 tuples (100%) done (elapsed 1.22 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.35 s (drop tables 0.04 s, create tables 0.02 s, client-side generate 1.30 s, vacuum 0.58 s, primary keys 0.40 s).
```

### with protocol=prepared tps = 21628 (excluding connections establishing)
```
[pg13-db1:postgres:~] # pgbench -S -t 100000 --protocol=prepared
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
query mode: prepared
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.046 ms
tps = 21610.733914 (including connections establishing)
tps = 21648.214302 (excluding connections establishing)
```

### without protocol=prepared tps = 11842 (excluding connections establishing)


```
[pg13-db1:postgres:~] # pgbench -S -t 100000
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.085 ms
tps = 11832.459453 (including connections establishing)
tps = 11842.211894 (excluding connections establishing)
```



## 10 partitions 

### setup

```
[pg13-db1:postgres:~] # pgbench -i --partitions=10 -s 5 --partition-method=range
dropping old tables...
creating tables...
creating 10 partitions...
generating data (client-side)...
500000 of 500000 tuples (100%) done (elapsed 1.47 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.38 s (drop tables 0.02 s, create tables 0.03 s, client-side generate 1.54 s, vacuum 0.45 s, primary keys 0.35 s).
```

### with protocol=prepared tps = 11037 (excluding connections establishing)
```
[pg13-db1:postgres:~] # pgbench -S -t 100000 --protocol=prepared
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 10
query mode: prepared
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.091 ms
tps = 11030.661562 (including connections establishing)
tps = 11036.548307 (excluding connections establishing)
```

### without protocol=prepared tps = 10417 (excluding connections establishing)


```
[pg13-db1:postgres:~] # pgbench -S -t 100000
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 10
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.096 ms
tps = 10410.137857 (including connections establishing)
tps = 10417.291966 (excluding connections establishing)
```




## 100 partitions 

### setup

```
[pg13-db1:postgres:~] # pgbench -i --partitions=100 -s 5 --partition-method=range
dropping old tables...
creating tables...
creating 100 partitions...
generating data (client-side)...
500000 of 500000 tuples (100%) done (elapsed 1.62 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.93 s (drop tables 0.03 s, create tables 0.25 s, client-side generate 1.72 s, vacuum 0.41 s, primary keys 0.52 s).
```

### with protocol=prepared tps = 10374 (excluding connections establishing)
```
[pg13-db1:postgres:~] # pgbench -S -t 100000 --protocol=prepared
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 100
query mode: prepared
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.096 ms
tps = 10366.901098 (including connections establishing)
tps = 10373.621020 (excluding connections establishing)
```

### without protocol=prepared tps = 10224 (excluding connections establishing)


```
[pg13-db1:postgres:~] # pgbench -S -t 100000
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 5
partition method: range
partitions: 100
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 100000
number of transactions actually processed: 100000/100000
latency average = 0.098 ms
tps = 10216.706413 (including connections establishing)
tps = 10224.037605 (excluding connections establishing)
```