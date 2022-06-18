
-- http://www.cems.uwe.ac.uk/~pchatter/resources/html/emp_dept_data+schema.html

DROP TABLE IF EXISTS dept;
DROP TABLE IF EXISTS salgrade;
DROP TABLE IF EXISTS emp;

CREATE TABLE salgrade(
grade integer not null primary key,
losal numeric,
hisal numeric);

CREATE TABLE dept(
deptno integer not null primary key,
dname varchar(50) not null,
location varchar(50) not null);

CREATE TABLE emp(
empno integer not null primary key,
ename varchar(50) not null,
job varchar(50) not null,
mgr integer,
hiredate date,
sal numeric,
comm numeric,
deptno integer not null);

insert into dept values (10,'Accounting','New York');
insert into dept values (20,'Research','Dallas');
insert into dept values (30,'Sales','Chicago');
insert into dept values (40,'Operations','Boston');

insert into emp values (7369,'SMITH','CLERK',7902,to_date('93/6/13','yy/mm/dd'),800,0.00,20);
insert into emp values (7499,'ALLEN','SALESMAN',7698,to_date('98/8/15','yy/mm/dd'),1600,300,30);
insert into emp values (7521,'WARD','SALESMAN',7698,to_date('96/3/26','yy/mm/dd'),1250,500,30);
insert into emp values (7566,'JONES','MANAGER',7839,to_date('95/10/31','yy/mm/dd'),2975,null,20);
insert into emp values (7698,'BLAKE','MANAGER',7839,to_date('92/6/11','yy/mm/dd'),2850,null,30);
insert into emp values (7782,'CLARK','MANAGER',7839,to_date('93/5/14','yy/mm/dd'),2450,null,10);
insert into emp values (7788,'SCOTT','ANALYST',7566,to_date('96/3/5','yy/mm/dd'),3000,null,20);
insert into emp values (7839,'KING','PRESIDENT',null,to_date('90/6/9','yy/mm/dd'),5000,0,10);
insert into emp values (7844,'TURNER','SALESMAN',7698,to_date('95/6/4','yy/mm/dd'),1500,0,30);
insert into emp values (7876,'ADAMS','CLERK',7788,to_date('99/6/4','yy/mm/dd'),1100,null,20);
insert into emp values (7900,'JAMES','CLERK',7698,to_date('00/6/23','yy/mm/dd'),950,null,30);
insert into emp values (7934,'MILLER','CLERK',7782,to_date('00/1/21','yy/mm/dd'),1300,null,10);
insert into emp values (7902,'FORD','ANALYST',7566,to_date('97/12/5','yy/mm/dd'),3000,null,20);
insert into emp values (7654,'MARTIN','SALESMAN',7698,to_date('98/12/5','yy/mm/dd'),1250,1400,30);


insert into salgrade values (1,700,1200);
insert into salgrade values (2,1201,1400);
insert into salgrade values (3,1401,2000);
insert into salgrade values (4,2001,3000);
insert into salgrade values (5,3001,99999);

