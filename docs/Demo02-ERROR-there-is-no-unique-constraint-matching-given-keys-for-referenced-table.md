## Demo02 - ERROR:  there is no unique constraint matching given keys for referenced table 

Adapting the [emp_and_dep_demo_pg.sql](emp_and_dep_demo_pg.sql)
```
~/projects/pg-ora-demo-scripts/docs $ diff emp_and_dep_demo_pg.sql emp_and_dep_demo_pg_unindex_fk_v1.sql 
14c14,15
< deptno integer not null primary key,
---
> --deptno integer not null primary key,
> deptno integer not null,
26c27
< deptno integer not null);
---
> deptno integer not null references dept(deptno));
```
i.e. the two changes above
* removed the pk (and so unique constraint) on dept.deptno
* add a foreign key `reference` from emp.deptno to dept.deptno 

this leads to CREATE TABLE failure `ERROR:  there is no unique constraint matching given keys for referenced table "dept"`

```
~/projects/pg-ora-demo-scripts/docs $ psql -f emp_and_dep_demo_pg_unindex_fk_v1.sql
CREATE TABLE
CREATE TABLE
psql:emp_and_dep_demo_pg_unindex_fk_v1.sql:27: ERROR:  there is no unique constraint matching given keys for referenced table "dept"
INSERT 0 1
...
```    

so this side has to be indexed, which I guess makes sense you wouldn't want duplicate entries in the parent table.                ^


