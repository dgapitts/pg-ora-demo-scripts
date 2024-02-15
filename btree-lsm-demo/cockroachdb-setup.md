# Cockroachdb setup 3 node cluster within docker





This was really clearly [explained here](https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-mac), although I did hit one gotcha ...

The network part was fine

```
davidpitts@Davids-MacBook-Pro learning-docker % docker network create -d bridge roachnet
8735d9f14641ed2b56ea2e2f5f71384668a7fca0aedbc9e9257dd9156c714894
davidpitts@Davids-MacBook-Pro learning-docker % docker volume create roach1
roach1
davidpitts@Davids-MacBook-Pro learning-docker % docker volume create roach2
roach2
davidpitts@Davids-MacBook-Pro learning-docker % docker volume create roach3
roach3
```

but then hit 
> Unable to find image 'cockroachdb/cockroach-unstable:v23.2.0' locally



```
davidpitts@Davids-MacBook-Pro learning-docker % docker run -d \
--name=roach1 \
--hostname=roach1 \
--net=roachnet \
-p 26257:26257 \
-p 8080:8080 \
-v "roach1:/cockroach/cockroach-data" \
cockroachdb/cockroach-unstable:v23.2.0 start \
  --advertise-addr=roach1:26357 \
  --http-addr=roach1:8080 \
  --listen-addr=roach1:26357 \
  --sql-addr=roach1:26257 \
  --insecure \
  --join=roach1:26357,roach2:26357,roach3:26357
Unable to find image 'cockroachdb/cockroach-unstable:v23.2.0' locally
docker: Error response from daemon: manifest for cockroachdb/cockroach-unstable:v23.2.0 not found: manifest unknown: manifest unknown.
See 'docker run --help'.
davidpitts@Davids-MacBook-Pro learning-docker % docker run -d \
--name=roach1 \
--hostname=roach1 \
--net=roachnet \
-p 26257:26257 \
-p 8080:8080 \
-v "roach1:/cockroach/cockroach-data" \
cockroachdb/cockroach-unstable:v23.1.0 start \
  --advertise-addr=roach1:26357 \
  --http-addr=roach1:8080 \
  --listen-addr=roach1:26357 \
  --sql-addr=roach1:26257 \
  --insecure \
  --join=roach1:26357,roach2:26357,roach3:26357
Unable to find image 'cockroachdb/cockroach-unstable:v23.1.0' locally
docker: Error response from daemon: manifest for cockroachdb/cockroach-unstable:v23.1.0 not found: manifest unknown: manifest unknown.
See 'docker run --help'.
```

so I just went with the latest release (which as below is v23.2.0-rc.2)
```
davidpitts@Davids-MacBook-Pro learning-docker % docker pull cockroachdb/cockroach-unstable:latest
latest: Pulling from cockroachdb/cockroach-unstable
f0427b721687: Pull complete
f8c712f64e35: Pull complete
4f4fb700ef54: Pull complete
91b9a92571e7: Pull complete
b83dc1b14689: Pull complete
cad9b6d33f80: Pull complete
46783ed346be: Pull complete
3e4f1652741c: Pull complete
Digest: sha256:4878952b1c33d61e10952096dfd1aed13984ff05066c55a51fb2455750485509
Status: Downloaded newer image for cockroachdb/cockroach-unstable:latest
docker.io/cockroachdb/cockroach-unstable:latest

What's Next?
  View a summary of image vulnerabilities and recommendations → docker scout quickview cockroachdb/cockroach-unstable:latest
```

```
davidpitts@Davids-MacBook-Pro learning-docker % docker run -d \
--name=roach1 \
--hostname=roach1 \
--net=roachnet \
-p 26257:26257 \
-p 8080:8080 \
-v "roach1:/cockroach/cockroach-data" \
cockroachdb/cockroach-unstable:latest start \
  --advertise-addr=roach1:26357 \
  --http-addr=roach1:8080 \
  --listen-addr=roach1:26357 \
  --sql-addr=roach1:26257 \
  --insecure \
  --join=roach1:26357,roach2:26357,roach3:26357
e23d9c0b4687d36aee0890d82619fcc1c34f8678c9408382d28c7254ab9abe61
davidpitts@Davids-MacBook-Pro learning-docker %   docker run -d \
  --name=roach2 \
  --hostname=roach2 \
  --net=roachnet \
  -p 26258:26258 \
  -p 8081:8081 \
  -v "roach2:/cockroach/cockroach-data" \
  cockroachdb/cockroach-unstable:latest start \
    --advertise-addr=roach2:26357 \
    --http-addr=roach2:8081 \
    --listen-addr=roach2:26357 \
    --sql-addr=roach2:26258 \
    --insecure \
    --join=roach1:26357,roach2:26357,roach3:26357
c45fe3e82df68e25bab7036e133ada715e4ddcfe0219028809e006946ba2fdf8
davidpitts@Davids-MacBook-Pro learning-docker %   docker run -d \
  --name=roach3 \
  --hostname=roach3 \
  --net=roachnet \
  -p 26259:26259 \
  -p 8082:8082 \
  -v "roach3:/cockroach/cockroach-data" \
  cockroachdb/cockroach-unstable:latest start \
    --advertise-addr=roach3:26357 \
    --http-addr=roach3:8082 \
    --listen-addr=roach3:26357 \
    --sql-addr=roach3:26259 \
    --insecure \
    --join=roach1:26357,roach2:26357,roach3:26357
5aa81c40c0d5ca47aedac15e8328e7825ebd499f2b2c0f0b655058fb8c500bd4
```

cockroach init

```
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach1 ./cockroach --host=roach1:26357 init --insecure
Cluster successfully initialized
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach1 grep 'node starting' /cockroach/cockroach-data/logs/cockroach.log -A 11
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +CockroachDB node starting at 2024-01-27 19:57:26.113523467 +0000 UTC m=+464.306316004 (took 464.1s)
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +build:               CCL v23.2.0-rc.2 @ 2024/01/08 20:51:56 (go1.21.5 X:nocoverageredesign)
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +webui:               ‹http://roach1:8080›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +sql:                 ‹postgresql://root@roach1:26257/defaultdb?sslmode=disable›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +sql (JDBC):          ‹jdbc:postgresql://roach1:26257/defaultdb?sslmode=disable&user=root›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +RPC client flags:    ‹/cockroach/cockroach <client cmd> --host=roach1:26357 --insecure›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +logs:                ‹/cockroach/cockroach-data/logs›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +temp dir:            ‹/cockroach/cockroach-data/cockroach-temp2010912884›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +external I/O path:   ‹/cockroach/cockroach-data/extern›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +store[0]:            ‹path=/cockroach/cockroach-data›
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +storage engine:      pebble
I240127 19:57:26.113595 74 1@cli/start.go:1242 ⋮ [T1,Vsystem,n1] 639 +clusterID:           ‹8f3d4b78-eb9c-4982-951c-5971abdc442a›
```

run some basic commands

```
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach1 ./cockroach sql --host=roach2:26258 --insecure
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v23.2.0-rc.2 (aarch64-unknown-linux-gnu, built 2024/01/08 20:51:56, go1.21.5 X:nocoverageredesign) (same version as client)
# Cluster ID: 8f3d4b78-eb9c-4982-951c-5971abdc442a
#
# Enter \? for a brief introduction.
#
root@roach2:26258/defaultdb> CREATE DATABASE bank;
CREATE DATABASE

Time: 19ms total (execution 19ms / network 0ms)

root@roach2:26258/defaultdb> CREATE TABLE bank.accounts (id INT PRIMARY KEY, balance DECIMAL);
CREATE TABLE

Time: 34ms total (execution 34ms / network 0ms)

root@roach2:26258/defaultdb> INSERT INTO bank.accounts VALUES (1, 1000.50);
INSERT 0 1

Time: 89ms total (execution 89ms / network 0ms)

root@roach2:26258/defaultdb> SELECT * FROM bank.accounts;
  id | balance
-----+----------
   1 | 1000.50
(1 row)

Time: 56ms total (execution 55ms / network 0ms)

root@roach2:26258/defaultdb> \q
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach2 ./cockroach --host=roach2:26258 sql --insecure
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v23.2.0-rc.2 (aarch64-unknown-linux-gnu, built 2024/01/08 20:51:56, go1.21.5 X:nocoverageredesign) (same version as client)
# Cluster ID: 8f3d4b78-eb9c-4982-951c-5971abdc442a
#
# Enter \? for a brief introduction.
#
root@roach2:26258/defaultdb> SELECT * FROM bank.accounts;
  id | balance
-----+----------
   1 | 1000.50
(1 row)

Time: 6ms total (execution 5ms / network 0ms)

root@roach2:26258/defaultdb>
```

start load test
```
root@roach2:26258/defaultdb> \q
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach1 ./cockroach workload init movr 'postgresql://root@roach1:26257?sslmode=disable'
I240127 20:00:15.871604 1 workload/cli/run.go:633  [-] 1  random seed: 7964320636782817603
I240127 20:00:15.881005 1 ccl/workloadccl/fixture.go:315  [-] 2  starting import of 6 tables
I240127 20:00:16.099824 66 ccl/workloadccl/fixture.go:492  [-] 3  imported 4.8 KiB in users table (50 rows, 0 index entries, took 179.886667ms, 0.03 MiB/s)
I240127 20:00:16.125195 71 ccl/workloadccl/fixture.go:492  [-] 4  imported 416 B in user_promo_codes table (5 rows, 0 index entries, took 205.200959ms, 0.00 MiB/s)
I240127 20:00:16.162149 69 ccl/workloadccl/fixture.go:492  [-] 5  imported 73 KiB in vehicle_location_histories table (1000 rows, 0 index entries, took 242.087125ms, 0.30 MiB/s)
I240127 20:00:16.196873 70 ccl/workloadccl/fixture.go:492  [-] 6  imported 214 KiB in promo_codes table (1000 rows, 0 index entries, took 276.805792ms, 0.75 MiB/s)
I240127 20:00:16.225405 67 ccl/workloadccl/fixture.go:492  [-] 7  imported 3.3 KiB in vehicles table (15 rows, 15 index entries, took 305.366001ms, 0.01 MiB/s)
I240127 20:00:17.619769 68 ccl/workloadccl/fixture.go:492  [-] 8  imported 154 KiB in rides table (500 rows, 1000 index entries, took 1.699782959s, 0.09 MiB/s)
I240127 20:00:17.619888 1 ccl/workloadccl/fixture.go:323  [-] 9  imported 450 KiB bytes in 6 tables (took 1.738812751s, 0.25 MiB/s)
I240127 20:00:17.634376 1 workload/workloadsql/workloadsql.go:148  [-] 10  starting 8 splits
I240127 20:00:17.712650 1 workload/workloadsql/workloadsql.go:148  [-] 11  starting 8 splits
I240127 20:00:17.786932 1 workload/workloadsql/workloadsql.go:148  [-] 12  starting 8 splits
davidpitts@Davids-MacBook-Pro learning-docker % time
shell  0.02s user 0.05s system 0% cpu 17:14.08 total
children  0.66s user 0.39s system 0% cpu 17:14.08 total
```
and finally generate some load
```
davidpitts@Davids-MacBook-Pro learning-docker % docker exec -it roach1 ./cockroach workload run movr --duration=5m 'postgresql://root@roach1:26257?sslmode=disable'
I240127 20:00:31.246195 1 workload/cli/run.go:633  [-] 1  random seed: 17037842029204821244
I240127 20:00:31.246288 1 workload/cli/run.go:432  [-] 2  creating load generator...
I240127 20:00:31.246377 1 workload/cli/run.go:471  [-] 3  creating load generator... done (took 88.708µs)
_elapsed___errors__ops/sec(inst)___ops/sec(cum)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)
    1.0s        0           10.0           10.0      1.7      2.0      2.0      2.0 addUser
    1.0s        0            2.0            2.0      2.5      3.5      3.5      3.5 addVehicle
    1.0s        0            1.0            1.0      7.9      7.9      7.9      7.9 applyPromoCode
    1.0s        0            1.0            1.0      4.5      4.5      4.5      4.5 createPromoCode
    1.0s        0          828.8          828.9      0.3      0.5      0.7      7.6 readVehicles
    1.0s        0           18.0           18.0      3.8      9.4     10.0     10.0 startRide
    1.0s        0           32.0           32.0     21.0     26.2     28.3     28.3 updateActiveRides
    2.0s        0            9.0            9.5      1.7      2.1      2.1      2.1 addUser
    2.0s        0            3.0            2.5      3.0      3.3      3.3      3.3 addVehicle
    2.0s        0            5.0            3.0      3.9      6.3      6.3      6.3 applyPromoCode
    2.0s        0            1.0            1.0      1.9      1.9      1.9      1.9 createPromoCode
    2.0s        0          651.1          740.0      0.3      0.5      0.7      7.1 readVehicles
    2.0s        0           12.0           15.0      3.5      4.1      4.1      4.1 startRide
    2.0s        0           30.0           31.0     22.0     28.3     29.4     29.4 updateActiveRides
    3.0s        0            4.0            7.7      1.4      1.8      1.8      1.8 addUser
    3.0s        0            5.0            3.3      2.4      2.8      2.8      2.8 addVehicle
    3.0s        0            2.0            2.7      3.4      3.8      3.8      3.8 applyPromoCode
    3.0s        0            3.0            1.7      1.9      2.2      2.2      2.2 createPromoCode
    3.0s        0            1.3            1.3      1.9      2.2      2.2      2.2 endRide
    3.0s        0          419.0          633.0      0.4      0.5      5.5      8.4 readVehicles
_elapsed___errors__ops/sec(inst)___ops/sec(cum)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)
    3.0s        0           16.0           15.3      3.8      4.5      8.4      8.4 startRide
    3.0s        0           34.0           32.0     22.0     23.1     37.7     37.7 updateActiveRides

...
_elapsed___errors__ops/sec(inst)___ops/sec(cum)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)
  298.0s        0           13.0           11.1      4.5      5.8      6.0      6.0 startRide
  298.0s        0           30.0           28.0     24.1     28.3     29.4     29.4 updateActiveRides
  299.0s        0            8.0            8.4      1.3      1.8      1.8      1.8 addUser
  299.0s        0            0.0            2.8      0.0      0.0      0.0      0.0 addVehicle
  299.0s        0            5.0            2.9      4.5      4.7      4.7      4.7 applyPromoCode
  299.0s        0            0.0            0.8      0.0      0.0      0.0      0.0 createPromoCode
  299.0s        0            6.0            2.1      1.8      2.1      2.1      2.1 endRide
  299.0s        0          630.3          534.3      0.5      0.7      0.9      4.1 readVehicles
  299.0s        0            8.0           11.1      4.2      5.8      5.8      5.8 startRide
  299.0s        0           27.0           28.0     22.0     28.3     37.7     37.7 updateActiveRides
  300.0s        0            8.0            8.4      1.2      1.8      1.8      1.8 addUser
  300.0s        0            4.0            2.8      3.4      3.7      3.7      3.7 addVehicle
  300.0s        0            1.0            2.9      4.7      4.7      4.7      4.7 applyPromoCode
  300.0s        0            0.0            0.8      0.0      0.0      0.0      0.0 createPromoCode
  300.0s        0            1.0            2.1      2.5      2.5      2.5      2.5 endRide
  300.0s        0          610.8          534.5      0.5      0.7      2.8      8.1 readVehicles
  300.0s        0           11.0           11.1      4.5      5.0      5.8      5.8 startRide
  300.0s        0           25.0           28.0     23.1     30.4     31.5     31.5 updateActiveRides

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0           2520            8.4      1.6      1.4      3.0      6.0     58.7  addUser

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0            835            2.8      3.1      2.9      5.0     10.0     25.2  addVehicle

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0            861            2.9      4.5      4.2      7.3     11.0     25.2  applyPromoCode

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0            233            0.8      1.8      1.6      3.4      5.8     11.5  createPromoCode

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0            625            2.1      2.2      1.8      4.7      7.1     46.1  endRide

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0         160356          534.5      0.5      0.5      0.7      1.1    209.7  readVehicles

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0           3336           11.1      4.3      3.9      6.8     11.0     27.3  startRide

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__total
  300.0s        0           8410           28.0     23.6     22.0     37.7     62.9    402.7  updateActiveRides

_elapsed___errors_____ops(total)___ops/sec(cum)__avg(ms)__p50(ms)__p95(ms)__p99(ms)_pMax(ms)__result
  300.0s        0         177176          590.6      1.7      0.5      7.1     25.2    402.7
 ```