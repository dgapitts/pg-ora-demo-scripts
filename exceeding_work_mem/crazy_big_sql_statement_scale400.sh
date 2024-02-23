python3 gen_crazy_big_sql_statement.py 400 > test_400.sql
#cat test_400.sql
psql -f test_400.sql >  test_400.log
#tail -10 test_400.log
echo `grep 'Execution Time:' test_400.log | awk '{print $3}'` " 400" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_400.log | awk '{print $3}'` " 400" | tee -a plan_times_gen_crazy_big_sql_statement.log

