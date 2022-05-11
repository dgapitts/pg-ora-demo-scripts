## Useful bits and pieces

### Customize psql with ~/.psqlrc - add useful alias commands with tab completion

I've added a [page on .psqlrc](psqlrc.md) this very useful features


### pg startup and running time
As per [how-can-i-get-my-servers-uptime](https://dba.stackexchange.com/questions/99428/how-can-i-get-my-servers-uptime):

```
[pg13centos7:vagrant:~] # psql -c "select current_timestamp - pg_postmaster_start_time() as uptime"
         uptime
------------------------
 2 days 19:10:28.614393
(1 row)

[pg13centos7:vagrant:~] # psql -c "select pg_postmaster_start_time() as uptime"
            uptime
-------------------------------
 2022-01-30 17:02:07.463197+00
(1 row)
```




## WAL Location and Sizing

### WAL Location

As per [Where is the postgresql wal located? How can I specify a different path?](https://stackoverflow.com/questions/19047954/where-is-the-postgresql-wal-located-how-can-i-specify-a-different-path)

This doesn't help with sizing recent WAL log generation, but I did like the notes shared here

> Descriptive Steps
Turn off Postgres to protect against corruption
Copy WAL directory (by default on Ubuntu - /var/lib/postgresql/<version>/main/pg_wal) to new file path using rsync. It will preserve file/folder permissions and folder structure with the -a flag. You should leave off the training slash.
Verify the contents copied correctly
Rename pg_wal to pg_wal-backup in the Postgres data directory ($PG_DATA)
Create a symbolic link to the new path to pg_wal in the Postgres data directory ($PG_DATA) and update the permissions of the symbolic link to be the postgres user
Start Postgres and verify that you can connect to the database
Optionally, delete the pg_wal-backup directory in the Postgres data directory ($PG_DATA)

```
# Matching Commands
sudo service postgresql stop

sudo rsync -av /var/lib/postgresql/12/main/pg_wal /<new_path>
ls -la /<new_path>

sudo mv /var/lib/postgresql/12/main/pg_wal /var/lib/postgresql/12/main/pg_wal-backup
sudo ln -s /<new_path> /var/lib/postgresql/12/main/pg_wal
sudo chown -h postgres:postgres /var/lib/postgresql/12/main/pg_wal

sudo service postgresql start && sudo service postgresql status
# Verify DB connection using your db credentials/information
psql -h localhost -U postgres -p 5432

rm -rf /var/lib/postgresql/12/main/pg_wal-backup
```

### WAL Sizing via bash commands

But getting back to WAL Sizing, [let add a flag](https://unix.stackexchange.com/questions/326762/how-to-change-created-time-stamp-one-week-ago)

```
[pg13centos7:postgres:~/13/data/pg_wal] # touch -d '-2 week' start
[pg13centos7:postgres:~/13/data/pg_wal] # ls -l start
-rw-r--r--. 1 postgres postgres 0 Jan 19 13:01 start
[pg13centos7:postgres:~/13/data/pg_wal] # ls -ltr |head
total 1048576
-rw-r--r--. 1 postgres postgres        0 Jan 19 13:01 start
drwx------. 2 postgres postgres        6 Jan 30 17:02 archive_status
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 00000001000000000000009E
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 00000001000000000000009F
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 0000000100000000000000A0
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 0000000100000000000000A1
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 0000000100000000000000A2
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 0000000100000000000000A3
-rw-------. 1 postgres postgres 16777216 Jan 31 09:07 0000000100000000000000A4
```


To find all the [files in say the last 10 days](https://stackoverflow.com/questions/801095/how-do-i-find-all-the-files-that-were-created-today-in-unix-linux)

```
[pg13centos7:postgres:~/13/data/pg_wal] # find . -mtime -10 -type f -print|wc -l
64
```

but for testing/demo purposes, I prefer the flag file approach

```
[pg13centos7:postgres:~/13/data/pg_wal] # find . -type f -newer start | wc -l
64
```






