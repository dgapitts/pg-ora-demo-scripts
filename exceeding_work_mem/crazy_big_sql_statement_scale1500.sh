python3 gen_crazy_big_sql_statement.py 1500 > test_1500.sql
#cat test_1500.sql
psql -f test_1500.sql >  test_1500.log
#tail -10 test_1500.log
echo `grep 'Execution Time:' test_1500.log | awk '{print $3}'` " 1500" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1500.log | awk '{print $3}'` " 1500" | tee -a plan_times_gen_crazy_big_sql_statement.log

