# auto_explain - setup notes and sample usage

Following [auto-explain docs](https://www.postgresql.org/docs/current/auto-explain.html) ...


## SETUP ... psql: error: FATAL:  could not access file "auto_explain": No such file or directory


### session_preload_libraries auto_explain

```
[pg13-db1:postgres:~] # psql
psql (13.7)
Type "help" for help.

[local] postgres@postgres=# show session_preload_libraries;
┌───────────────────────────┐
│ session_preload_libraries │
├───────────────────────────┤
│                           │
└───────────────────────────┘
(1 row)
```

after adding this to postgresql.conf
```
[pg13-db1:postgres:~] # tail -1 ./13/data/postgresql.conf
session_preload_libraries = 'auto_explain'
```

and restarting seems okay

```
[pg13-db1:root:~] # systemctl restart postgresql-13
[pg13-db1:root:~] # su - postgres
Last login: Thu May 26 22:08:16 UTC 2022 on pts/2
[pg13-db1:postgres:~] # psql
psql: error: FATAL:  could not access file "auto_explain": No such file or directory
```


```
[pg13-db1:postgres:~] # psql
psql: error: FATAL:  could not access file "auto_explain": No such file or directory
```

the solution was `yum install postgresql13-contrib`

```
[pg13-db1:root:~] # yum list installed |grep -i  postgres
Failed to set locale, defaulting to C
postgresql13.x86_64                13.7-1PGDG.rhel7                    @pgdg13
postgresql13-libs.x86_64           13.7-1PGDG.rhel7                    @pgdg13
postgresql13-server.x86_64         13.7-1PGDG.rhel7                    @pgdg13
[pg13-db1:root:~] # yum install postgresql13-contrib
Failed to set locale, defaulting to C
...
```

NB this is kinda of wierd as I thought this was included 

```
ects/vagrant-c7-pg13-pg13 $ grep postgresql13-contrib *sh
provision.sh:  yum -y install postgresql13-contrib postgresql13-libs postgresql13-devel
provision_base.sh:  yum -y install postgresql13-contrib postgresql13-libs postgresql13-devel
```