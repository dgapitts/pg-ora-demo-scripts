## Summary for brew install postgresql@15 

Im the past I didn't specify a pg version  

* [Quick setup notes for Mac (`brew install postgresql`)](Quick-setup-notes-for-Mac.md)

Now it seems normal to explicit install `postgresql@13` or `postgresql@14` or `postgresql@15`

* Making the pg version explicit seems like good general practise - better clarity
* Easier to run regression testing e.g  `postgresql@13` vs `postgresql@14` or `postgresql@15`
* To see the setup detials `brew info postgresql@15`
* you don't need to run `initdb` but you do need run `pgctl` to start pg15  
* again running 
```
createdb `whoami`
```
make things easier for mac users 

## Details
```
davep ~ % brew info postgresql@15
==> postgresql@15: stable 15.1 (bottled) [keg-only]
Object-relational database system
https://www.postgresql.org/
/opt/homebrew/Cellar/postgresql@15/15.1 (3,345 files, 45.6MB)
  Poured from bottle on 2022-12-13 at 10:46:34
From: https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/postgresql@15.rb
License: PostgreSQL
==> Dependencies
Build: pkg-config ✘
Required: icu4c ✔, krb5 ✔, lz4 ✔, openssl@1.1 ✔, readline ✔
==> Caveats
This formula has created a default database cluster with:
  initdb --locale=C -E UTF-8 /opt/homebrew/var/postgresql@15
For more details, read:
  https://www.postgresql.org/docs/15/app-initdb.html

postgresql@15 is keg-only, which means it was not symlinked into /opt/homebrew,
because this is an alternate version of another formula.

If you need to have postgresql@15 first in your PATH, run:
  echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc

For compilers to find postgresql@15 you may need to set:
  export LDFLAGS="-L/opt/homebrew/opt/postgresql@15/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/postgresql@15/include"


To restart postgresql@15 after an upgrade:
  brew services restart postgresql@15
Or, if you don't want/need a background service you can just run:
  /opt/homebrew/opt/postgresql@15/bin/postgres -D /opt/homebrew/var/postgresql@15
==> Analytics
install: 5,321 (30 days), 9,361 (90 days), 9,361 (365 days)
install-on-request: 5,318 (30 days), 9,356 (90 days), 9,356 (365 days)
build-error: 5 (30 days)
```


```
davep ~ % initdb --locale=C -E UTF-8 /opt/homebrew/var/postgresql@15
The files belonging to this database system will be owned by user "davep".
This user must also own the server process.

The database cluster will be initialized with locale "C".
The default text search configuration will be set to "english".

Data page checksums are disabled.

initdb: error: directory "/opt/homebrew/var/postgresql@15" exists but is not empty
initdb: hint: If you want to create a new database system, either remove or empty the directory "/opt/homebrew/var/postgresql@15" or run initdb with an argument other than "/opt/homebrew/var/postgresql@15".
```

```
davep ~ % pg_ctl -D /opt/homebrew/var/postgresql@15 start
waiting for server to start....2022-12-13 10:52:30.543 CET [38144] LOG:  starting PostgreSQL 15.1 (Homebrew) on aarch64-apple-darwin21.6.0, compiled by Apple clang version 14.0.0 (clang-1400.0.29.202), 64-bit
2022-12-13 10:52:30.546 CET [38144] LOG:  listening on IPv6 address "::1", port 5432
2022-12-13 10:52:30.546 CET [38144] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2022-12-13 10:52:30.547 CET [38144] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2022-12-13 10:52:30.549 CET [38147] LOG:  database system was shut down at 2022-12-13 10:46:41 CET
2022-12-13 10:52:30.552 CET [38144] LOG:  database system is ready to accept connections
 done
server started
davep ~ % psql
2022-12-13 10:52:39.002 CET [38152] FATAL:  database "davep" does not exist
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  database "davep" does not exist
davep ~ % createdb `whoami`
davep ~ % psql
psql (15.1 (Homebrew))
Type "help" for help.

davep=# \q
davep ~ % createdb pgbench
davep ~ % pgbench -i -s 15 -d pgbench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
1500000 of 1500000 tuples (100%) done (elapsed 1.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.51 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 1.07 s, vacuum 0.10 s, primary keys 0.35 s).
```