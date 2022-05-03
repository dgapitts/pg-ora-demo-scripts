### pgbench: command not found 

Getting this as postgres user

```
-bash-4.2$ id
uid=26(postgres) gid=26(postgres) groups=26(postgres) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
-bash-4.2$ pgbench
-bash: pgbench: command not found
```

These are postgres package
```
[vagrant@pg13-db2 ~]$ yum list installed|grep postgres
Failed to set locale, defaulting to C
postgresql13.x86_64                13.6-1PGDG.rhel7                    @pgdg13
postgresql13-libs.x86_64           13.6-1PGDG.rhel7                    @pgdg13
postgresql13-server.x86_64         13.6-1PGDG.rhel7                    @pgdg13
```

According [this document](https://linuxtut.com/en/e9316fecd57bff6679cd/) 

> Benchmark tool pgbench is included as standard in PostgreSQL.


Then I spotted something quirky i.e. pgbench is in the root path but not Postgres

```
[root@pg13-db1 ~]# which pgbench
/usr/pgsql-13/bin/pgbench
```

Switching back to postgres

```
[root@pg13-db1 ~]# su - postgres
Last login: Sun May  1 00:23:08 UTC 2022 on pts/0
-bash-4.2$ which pgbench
/usr/bin/which: no pgbench in (/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin)
``` 

the short term fix is

```
-bash-4.2$ /usr/pgsql-13/bin/pgbench -i --partitions=3 --partition-method=range
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
creating 3 partitions...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.13 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.51 s (drop tables 0.01 s, create tables 0.05 s, client-side generate 0.18 s, vacuum 0.22 s, primary keys 0.05 s).
```

longer term, it looks I would normally automate this via my `bashrc.append.txt` (which is 

```
provision.sh:  echo 'export PATH="$PATH:/usr/pgsql-13/bin"' >> /vagrant/bashrc.append.txt
provision_base.sh:  echo 'export PATH="$PATH:/usr/pgsql-13/bin"' >> /vagrant/bashrc.append.txt
```

i.e. [this commit](https://github.com/dgapitts/vagrant-c7-pg13-pg13/commit/6aeefb6350d7273ad91f60eaa0316d572970ea99) to the `vagrant-c7-pg13-pg13` project.

