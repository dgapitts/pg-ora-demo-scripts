## Intro - generic-fillfactor 

The very first you run this, you need to setup the fillfactor database
```
psql -c "create database fillfactor;"
```

You could run 
* `./build_new_schema_setup_tables.sh test100k` to populate three 100k tables with fillfactors of 80, 90 and 100
* `./batch_test100k.sh 3 10000 7` i.e. using mod(3) for every 3rd row and 7 batches of 10000 updates  i.e.  to test whether we get hot updates or regular updates with fillfactors  80, 90 and 100 
* `./drop_schema.sh test100k` to cleanup

I often end up wrapping these together
```
./drop_schema.sh test100k; ./build_new_schema_setup_tables.sh test100k;./batch_test100k.sh 3 10000 7
```


There are a lot of metrics logged but the first thing to highlight is that 
* with ff80, the first 10K updates are all HOT and they remain all HOT
* with ff90, the first 10K updates are about 2/3 HOT and 1/3 non-HOT with the proportion of HOT updates getting better over time/batches 
* with ff90, the first 10K updates are all non-HOT with the proportion of HOT updates getting better very slowly over time/batches 


```
~/projects/pg-ora-demo-scripts/demo/generic-fillfactor $ grep -A4  dead logs/batch_test100k_batchsize10000_mod3_numbatches7_220816-190440.log|grep 'dead\|ff80'
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |         0 |             0 |     100001 |          0
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     10000 |         10000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     20000 |         20000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     30000 |         30000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     40000 |         40000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     50000 |         50000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     60000 |         60000 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff80_100  | 72 MB     | 39 MB      | 33 MB      |     70000 |         70000 |     100001 |      10000
~/projects/pg-ora-demo-scripts/demo/generic-fillfactor $ grep -A4  dead logs/batch_test100k_batchsize10000_mod3_numbatches7_220816-190440.log|grep 'dead\|ff90'
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 68 MB     | 36 MB      | 33 MB      |         0 |             0 |     100001 |          0
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 70 MB     | 36 MB      | 34 MB      |     10000 |          6819 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 71 MB     | 37 MB      | 34 MB      |     20000 |         14410 |     100001 |      13181
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 71 MB     | 37 MB      | 34 MB      |     30000 |         22276 |     100001 |      17760
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 72 MB     | 37 MB      | 34 MB      |     40000 |         30385 |     100001 |      19676
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 72 MB     | 38 MB      | 34 MB      |     50000 |         38708 |     100001 |      24360
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 72 MB     | 38 MB      | 34 MB      |     60000 |         47225 |     100001 |      24598
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff90_100  | 73 MB     | 38 MB      | 34 MB      |     70000 |         55909 |     100001 |      29260
~/projects/pg-ora-demo-scripts/demo/generic-fillfactor $ grep -A4  dead logs/batch_test100k_batchsize10000_mod3_numbatches7_220816-190440.log|grep 'dead\|ff100'
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 64 MB     | 31 MB      | 33 MB      |         0 |             0 |     100001 |          0
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 69 MB     | 33 MB      | 36 MB      |     10000 |             0 |     100001 |      10000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 71 MB     | 35 MB      | 36 MB      |     20000 |             0 |     100001 |      20000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 73 MB     | 37 MB      | 36 MB      |     30000 |             3 |     100001 |      30000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 75 MB     | 39 MB      | 36 MB      |     40000 |            13 |     100001 |      40000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 78 MB     | 41 MB      | 37 MB      |     50000 |            37 |     100001 |      50000
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 80 MB     | 43 MB      | 37 MB      |     60000 |            74 |     100001 |      59986
 schemaname |  relname  | full_size | table_size | index_size | n_tup_upd | n_tup_hot_upd | n_live_tup | n_dead_tup 
 test100k   | ff100_100 | 82 MB     | 45 MB      | 37 MB      |     70000 |           126 |     100001 |      69959
```
