python3 gen_crazy_big_sql_statement.py 2000 > test_2000.sql
#cat test_2000.sql
psql -f test_2000.sql >  test_2000.log
#tail -10 test_2000.log
echo `grep 'Execution Time:' test_2000.log | awk '{print $3}'` " 2000" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_2000.log | awk '{print $3}'` " 2000" | tee -a plan_times_gen_crazy_big_sql_statement.log

