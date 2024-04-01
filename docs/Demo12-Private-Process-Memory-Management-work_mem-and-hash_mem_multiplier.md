## Private Process Memory Management -  work_mem and hash_mem_multiplier


### Summary

Tuning postgres private memory management is quite complex for two reasons
* What proportion of the memory 
* work_mem is a uniform limit ovoer max_connection e.g. if you have a 16000M VM and you say 25% for private processes i.e 4000M and you need max_connection of 500 then work_mem = 8MB 
* in pg13 there is also a hash_mem_multiplier, for hash operations so some processes can now exceed work_mem - however in pg13 and pg14 the default value is 1 i.e. no change with default
* in pg15 the default value is 2 i.e. some risk this new feature can catch people out


#### hash_mem_multiplier (floating point) 

This multiple for hash operations was introduced in pg13

> Used to compute the maximum amount of memory that hash-based operations can use. The final limit is determined by multiplying work_mem by hash_mem_multiplier. The default value is 2.0, which makes hash-based operations use twice the usual work_mem base amount.
Consider increasing hash_mem_multiplier in environments where spilling by query operations is a regular occurrence, especially when simply increasing work_mem results in memory pressure (memory pressure typically takes the form of intermittent out of memory errors). The default setting of 2.0 is often effective with mixed workloads. 
https://www.postgresql.org/docs/current/runtime-config-resource.html



### Examples

Setup (starting from citus columnar demo)
```
davidpitts=# CREATE TABLE perf_row(
  c00 int8, c01 int8, c02 int8, c03 int8, c04 int8, c05 int8, c06 int8, c07 int8, c08 int8, c09 int8,
  c10 int8, c11 int8, c12 int8, c13 int8, c14 int8, c15 int8, c16 int8, c17 int8, c18 int8, c19 int8,
  c20 int8, c21 int8, c22 int8, c23 int8, c24 int8, c25 int8, c26 int8, c27 int8, c28 int8, c29 int8,
  c30 int8, c31 int8, c32 int8, c33 int8, c34 int8, c35 int8, c36 int8, c37 int8, c38 int8, c39 int8,
  c40 int8, c41 int8, c42 int8, c43 int8, c44 int8, c45 int8, c46 int8, c47 int8, c48 int8, c49 int8,
  c50 int8, c51 int8, c52 int8, c53 int8, c54 int8, c55 int8, c56 int8, c57 int8, c58 int8, c59 int8,
  c60 int8, c61 int8, c62 int8, c63 int8, c64 int8, c65 int8, c66 int8, c67 int8, c68 int8, c69 int8,
  c70 int8, c71 int8, c72 int8, c73 int8, c74 int8, c75 int8, c76 int8, c77 int8, c78 int8, c79 int8,
  c80 int8, c81 int8, c82 int8, c83 int8, c84 int8, c85 int8, c86 int8, c87 int8, c88 int8, c89 int8,
  c90 int8, c91 int8, c92 int8, c93 int8, c94 int8, c95 int8, c96 int8, c97 int8, c98 int8, c99 int8
);
```
and loading 500000 rows with 500 distinct
```
CREATE TABLE
davidpitts=# INSERT INTO perf_row
  SELECT
    g % 00500, g % 01000, g % 01500, g % 02000, g % 02500, g % 03000, g % 03500, g % 04000, g % 04500, g % 05000,
    g % 05500, g % 06000, g % 06500, g % 07000, g % 07500, g % 08000, g % 08500, g % 09000, g % 09500, g % 10000,
    g % 10500, g % 11000, g % 11500, g % 12000, g % 12500, g % 13000, g % 13500, g % 14000, g % 14500, g % 15000,
    g % 15500, g % 16000, g % 16500, g % 17000, g % 17500, g % 18000, g % 18500, g % 19000, g % 19500, g % 20000,
    g % 20500, g % 21000, g % 21500, g % 22000, g % 22500, g % 23000, g % 23500, g % 24000, g % 24500, g % 25000,
    g % 25500, g % 26000, g % 26500, g % 27000, g % 27500, g % 28000, g % 28500, g % 29000, g % 29500, g % 30000,
    g % 30500, g % 31000, g % 31500, g % 32000, g % 32500, g % 33000, g % 33500, g % 34000, g % 34500, g % 35000,
    g % 35500, g % 36000, g % 36500, g % 37000, g % 37500, g % 38000, g % 38500, g % 39000, g % 39500, g % 40000,
    g % 40500, g % 41000, g % 41500, g % 42000, g % 42500, g % 43000, g % 43500, g % 44000, g % 44500, g % 45000,
    g % 45500, g % 46000, g % 46500, g % 47000, g % 47500, g % 48000, g % 48500, g % 49000, g % 49500, g % 50000
  FROM generate_series(1,500000) g;
INSERT 0 500000
```
Three demos
*  c99 - 50000 distinct values to aggregate over
*  c70 - 35000 distinct values to aggregate over
*  c00 - 500 distinct values to aggregate over

are with the default 4Mb work_mem


```
davidpitts=# show work_mem;
 work_mem
----------
 4MB
(1 row)
```

the default hash_mem_multiplier is 2

```
davidpitts=# show hash_mem_multiplier;
 hash_mem_multiplier
---------------------
 2
(1 row)
```


NB I also disabled parallelisation to make the plans easier to read

``````
davidpitts=# SET max_parallel_workers_per_gather = 0;
SET
``````

but through the demo's we will vary this to show higher 


## Demo 01 - high cardinality (c99) - 50,000 distinct values to aggregate over

### hash_mem_multiplier=1 - Memory Usage: 4145kB  Disk Usage: 23496kB, temp read=2641 written=4909

This is affectively how postgres used to work by default pre-pg15
```
davidpitts=# set hash_mem_multiplier=1;
SET

davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c99, SUM(c29), AVG(c71) FROM perf_row GROUP BY c99;
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=97743.84..104357.10 rows=50256 width=72) (actual time=1697.361..2050.372 rows=50000 loops=1)
   Group Key: c99
   Planned Partitions: 4  Batches: 5  Memory Usage: 4145kB  Disk Usage: 23496kB
   Buffers: shared hit=15688 read=39868, temp read=2641 written=4909
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=2.007..833.247 rows=500000 loops=1)
         Buffers: shared hit=15688 read=39868
 Planning Time: 0.513 ms
 Execution Time: 2056.596 ms
(8 rows)
```

### hash_mem_multiplier=2 - Memory Usage: 8241kB  Disk Usage: 14104kB, temp read=1525 written=2896

This is affectively how postgres used to work by default pre-pg15
```
davidpitts=# set hash_mem_multiplier=2;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c99, SUM(c29), AVG(c71) FROM perf_row GROUP BY c99;
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=97743.84..104357.10 rows=50256 width=72) (actual time=1480.648..1689.421 rows=50000 loops=1)
   Group Key: c99
   Planned Partitions: 4  Batches: 5  Memory Usage: 8241kB  Disk Usage: 14104kB
   Buffers: shared hit=15688 read=39868, temp read=1525 written=2896
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.700..825.849 rows=500000 loops=1)
         Buffers: shared hit=15688 read=39868
 Planning Time: 0.096 ms
 Execution Time: 1701.970 ms
(8 rows)
```

### hash_mem_multiplier=3 - Memory Usage: 12337kB  Disk Usage: 1632kB, temp read=151 written=313


```
davidpitts=# set hash_mem_multiplier=3;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c99, SUM(c29), AVG(c71) FROM perf_row GROUP BY c99;
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64306.07..65059.91 rows=50256 width=72) (actual time=329.444..345.424 rows=50000 loops=1)
   Group Key: c99
   Batches: 5  Memory Usage: 12337kB  Disk Usage: 1632kB
   Buffers: shared hit=15758 read=39798, temp read=151 written=313
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.598..157.149 rows=500000 loops=1)
         Buffers: shared hit=15758 read=39798
 Planning Time: 0.132 ms
 Execution Time: 347.846 ms
(8 rows)         
```

### hash_mem_multiplier=4 - Memory Usage: 12561kB and no Disk Usage

```
davidpitts=# set hash_mem_multiplier=4;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c99, SUM(c29), AVG(c71) FROM perf_row GROUP BY c99;
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64306.07..65059.91 rows=50256 width=72) (actual time=247.716..257.823 rows=50000 loops=1)
   Group Key: c99
   Batches: 1  Memory Usage: 12561kB
   Buffers: shared hit=15822 read=39734
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.226..88.872 rows=500000 loops=1)
         Buffers: shared hit=15822 read=39734
 Planning Time: 0.202 ms
 Execution Time: 259.452 ms
(8 rows)
```



## Demo 02 - loower cardinality (c00) - 500 distinct values to aggregate over

### hash_mem_multiplier=1 - Memory Usage: 169kB  - no overflow to disc

This is affectively how postgres used to work by default pre-pg15
```
davidpitts=# set hash_mem_multiplier=1;
SET

davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c00, SUM(c29), AVG(c71) FROM perf_row GROUP BY c00;
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64306.07..64313.57 rows=500 width=72) (actual time=565.246..565.323 rows=500 loops=1)
   Group Key: c00
   Batches: 1  Memory Usage: 169kB
   Buffers: shared hit=15752 read=39804
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.296..364.305 rows=500000 loops=1)
         Buffers: shared hit=15752 read=39804
 Planning Time: 0.169 ms
 Execution Time: 565.536 ms
(8 rows)
```

## Demo 03 - higher cardinality (c70) - 35500 distinct values to aggregate over

### hash_mem_multiplier=1 - Memory Usage: 4145kB  Disk Usage: 19496kB

This is affectively how postgres used to work by default pre-pg15
```
davidpitts=# set hash_mem_multiplier=1;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c70, SUM(c29), AVG(c71) FROM perf_row GROUP BY c70;
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=97743.84..104134.09 rows=35389 width=72) (actual time=1380.927..1565.046 rows=35500 loops=1)
   Group Key: c70
   Planned Partitions: 4  Batches: 5  Memory Usage: 4145kB  Disk Usage: 19496kB
   Buffers: shared hit=15688 read=39868, temp read=2207 written=4087
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.818..768.109 rows=500000 loops=1)
         Buffers: shared hit=15688 read=39868
 Planning Time: 11.207 ms
 Execution Time: 1580.700 ms
(8 rows)

```


### hash_mem_multiplier=2 - Memory Usage: 8241kB  Disk Usage: 7224kB

This is the default postgres behaviour pg15 and beyond
```
davidpitts=# set hash_mem_multiplier=2;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c70, SUM(c29), AVG(c71) FROM perf_row GROUP BY c70;
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=97743.84..104134.09 rows=35389 width=72) (actual time=247.384..263.229 rows=35500 loops=1)
   Group Key: c70
   Batches: 5  Memory Usage: 8241kB  Disk Usage: 7224kB
   Buffers: shared hit=15643 read=39913, temp read=644 written=1377
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.750..79.638 rows=500000 loops=1)
         Buffers: shared hit=15643 read=39913
 Planning Time: 0.132 ms
 Execution Time: 266.082 ms
(8 rows)
```

### hash_mem_multiplier=3 -  Memory Usage: 9489kB, No Disk Usage


```
davidpitts=# set hash_mem_multiplier=3;
SET
davidpitts=# EXPLAIN (ANALYZE, BUFFERS) SELECT c70, SUM(c29), AVG(c71) FROM perf_row GROUP BY c70;
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=64306.07..64836.90 rows=35389 width=72) (actual time=194.070..200.619 rows=35500 loops=1)
   Group Key: c70
   Batches: 1  Memory Usage: 9489kB
   Buffers: shared hit=15685 read=39871
   ->  Seq Scan on perf_row  (cost=0.00..60556.04 rows=500004 width=24) (actual time=0.183..75.247 rows=500000 loops=1)
         Buffers: shared hit=15685 read=39871
 Planning Time: 0.751 ms
 Execution Time: 202.032 ms
(8 rows)   
```
