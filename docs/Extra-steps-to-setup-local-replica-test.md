## Extra steps to setup local replica (for testing)


```
systemctl status postgresql-13.service 
su - postgres -c 'echo "ALTER SYSTEM SET listen_addresses TO '\''*'\''"|psql'
su - postgres -c 'echo "show  listen_addresses"|psql'
systemctl restart postgresql-13.service 
su - postgres -c 'echo "show  listen_addresses"|psql'
su - postgres -c 'echo " CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '\''secret'\''"|psql' 
ip a
ping 10.0.2.15
su - postgres -c 'echo "host replication replicator 10.0.2.15/32 md5" >> $PGDATA/pg_hba.conf'
su - postgres -c 'psql -c "select pg_reload_conf()"'
su - postgres -c "mkdir /var/lib/pgsql/13/data_replica"
su - postgres -c "chmod 700 /var/lib/pgsql/13/data_replica"
su - postgres -c "pg_basebackup -h 10.0.2.15 -U replicator -p 5432 -D /var/lib/pgsql/13/data_replica -Fp -Xs -P -R"
su - postgres -c 'pg_ctl -D /var/lib/pgsql/13/data_replica -o "-F -p 5433" start'
su - postgres -c 'pg_ctl -D /var/lib/pgsql/13/data_replica -o "-F -p 5433" status'
```
