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

### Cleanup pg_wal on mac - `touch` works differently on mac


Running some heavy FF tests down to 2.1G of freespace and I have nearly 3G of WAL (on my macair)

```
/usr/local/var/postgres $ du -hs *
4.0K	PG_VERSION
512M	base
612K	global
4.0K	logfile
...
2.8G	pg_wal
8.0K	pg_xact
...
/usr/local/var/postgres $ df -h .
Filesystem     Size   Used  Avail Capacity iused      ifree %iused  Mounted on
/dev/disk1s1  234Gi  215Gi  2.1Gi   100% 2569927 2446555433    0%   /System/Volumes/Data
/usr/local/var/postgres $ cd pg_wal/
/usr/local/var/postgres/pg_wal $ ls -lh|wc -l
     179
/usr/local/var/postgres/pg_wal $ ls -lh|head
total 5799936
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000001
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000002
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000003
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000004
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000005
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000006
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000007
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000008
-rw-------  1 dave  staff    16M Aug 16 15:36 000000010000000000000009
/usr/local/var/postgres/pg_wal $ man touch
```


`touch` works differently on mac (maybe I should install standard gnu tools)

```
     The following options are available:

     -A      Adjust the access and modification time stamps for the file by the specified value.  This flag is intended for use in modifying files with
             incorrectly set time stamps.

             The argument is of the form ``[-][[hh]mm]SS'' where each pair of letters represents the following:

                   -       Make the adjustment negative: the new time stamp is set to be before the old one.
                   hh      The number of hours, from 00 to 99.
                   mm      The number of minutes, from 00 to 59.
                   SS      The number of seconds, from 00 to 59.

             The -A flag implies the -c flag: if any file specified does not exist, it will be silently ignored.

...

     -c      Do not create the file if it does not exist.  The touch utility does not treat this as an error.  No error messages are displayed and the exit
             value is not affected.

```


i.e. to cleanup every over 13 hours ago `touch start_flag;ls -l start_flag;touch -A '-130000' start_flag;ls -l start_flag ` 

```
/usr/local/var/postgres/pg_wal $ touch start_flag
/usr/local/var/postgres/pg_wal $ ls -l start_flag 
-rw-r--r--  1 dave  staff  0 Aug 17 07:29 start_flag
/usr/local/var/postgres/pg_wal $ touch -A '-130000' start_flag
/usr/local/var/postgres/pg_wal $ ls -l start_flag 
-rw-r--r--  1 dave  staff  0 Aug 16 06:29 start_flag
/usr/local/var/postgres/pg_wal $ find . -type f -newer start_flag -exec ls -l {} +
-rw-------  1 dave  staff  16777216 Aug 16 15:36 ./000000010000000000000001
-rw-------  1 dave  staff  16777216 Aug 16 15:36 ./000000010000000000000003
...
-rw-------  1 dave  staff  16777216 Aug 16 19:04 ./0000000100000000000000AE
-rw-------  1 dave  staff  16777216 Aug 16 19:04 ./0000000100000000000000AF
-rw-------  1 dave  staff  16777216 Aug 16 19:05 ./0000000100000000000000B0
-rw-------  1 dave  staff  16777216 Aug 16 19:09 ./0000000100000000000000B1
/usr/local/var/postgres/pg_wal $ find . -type f -newer start_flag -delete
/usr/local/var/postgres/pg_wal $ df -h .
Filesystem     Size   Used  Avail Capacity iused      ifree %iused  Mounted on
/dev/disk1s1  234Gi  212Gi  4.8Gi    98% 2570098 2446555262    0%   /System/Volumes/Data
```




