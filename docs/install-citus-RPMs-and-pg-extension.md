## Install citus RPMs and pg extension

Add the citusdata repo's 
```
curl https://install.citusdata.com/community/rpm.sh | sudo bash
```

review the citus repository 
```
yum list available|grep citus
```

I'm choosing the pg12 version
```
sudo yum install -y citus102_12
```

Check if you have any `shared_preload_libraries`
```
grep shared_preload_libraries /var/lib/pgsql/12/data/postgresql.conf
```
in my case there were no existing settings to worry about, so I used the following simple logic
```
echo "shared_preload_libraries = 'citus'" | sudo tee -a /var/lib/pgsql/12/data/postgresql.conf
```

then you need to restart postgres
```
service postgresql-12 status
service postgresql-12 restart
service postgresql-12 status
```
note you need a full restart and not a reload
```
service postgresql-12 reload
```
and final as the `postgres` user
```
postgres=# CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION
```

