python3 gen_crazy_big_sql_statement.py 700 > test_700.sql
#cat test_700.sql
psql -f test_700.sql >  test_700.log
#tail -10 test_700.log
echo `grep 'Execution Time:' test_700.log | awk '{print $3}'` " 700" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_700.log | awk '{print $3}'` " 700" | tee -a plan_times_gen_crazy_big_sql_statement.log

