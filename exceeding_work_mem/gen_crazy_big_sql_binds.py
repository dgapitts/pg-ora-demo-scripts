import sys

#limit=10
limit=int(sys.argv[1])

"""
This is our starting point

explain (analyze,buffers)
select alias_pgbench_accounts_1.abalance+alias_pgbench_accounts_2.abalance
from
(select abalance from pgbench_accounts where aid = 1) alias_pgbench_accounts_1,
(select abalance from pgbench_accounts where aid = 2) alias_pgbench_accounts_2;

psql >

                                                                           QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.58..16.63 rows=1 width=4) (actual time=0.020..0.021 rows=1 loops=1)
   Buffers: shared hit=6
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts  (cost=0.29..8.31 rows=1 width=4) (actual time=0.014..0.014 rows=1 loops=1)
         Index Cond: (aid = 1)
         Buffers: shared hit=3
   ->  Index Scan using pgbench_accounts_pkey on pgbench_accounts pgbench_accounts_1  (cost=0.29..8.31 rows=1 width=4) (actual time=0.005..0.005 rows=1 loops=1)
         Index Cond: (aid = 2)
         Buffers: shared hit=3
 Planning Time: 0.140 ms
 Execution Time: 0.035 ms
(10 rows)
"""

crazy_big_sql_statement=""
for i in range(1,limit):
      crazy_big_sql_statement+="\set b"+str(i)+" "+str(i)+"\n"


crazy_big_sql_statement+="explain (analyze,buffers) select sum(abalance) from pgbench_accounts where aid = :b1 or \n"


for i in range(2,limit):
    crazy_big_sql_statement+="aid = :b"+str(i)+" or \n"

crazy_big_sql_statement+="aid = :b"+str(i)
print(crazy_big_sql_statement)

