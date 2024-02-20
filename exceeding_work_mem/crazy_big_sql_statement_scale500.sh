python3 gen_crazy_big_sql_statement.py 500 > test_500.sql
#cat test_500.sql
psql -f test_500.sql >  test_500.log
#tail -10 test_500.log
echo `grep 'Execution Time:' test_500.log | awk '{print $3}'` " 500" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_500.log | awk '{print $3}'` " 500" | tee -a plan_times_gen_crazy_big_sql_statement.log

