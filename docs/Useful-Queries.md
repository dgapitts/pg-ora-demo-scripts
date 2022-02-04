## Useful-Queries


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