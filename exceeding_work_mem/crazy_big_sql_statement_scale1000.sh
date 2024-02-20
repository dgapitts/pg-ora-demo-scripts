python3 gen_crazy_big_sql_statement.py 1000 > test_1000.sql
#cat test_1000.sql
psql -f test_1000.sql >  test_1000.log
#tail -10 test_1000.log
echo `grep 'Execution Time:' test_1000.log | awk '{print $3}'` " 1000" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1000.log | awk '{print $3}'` " 1000" | tee -a plan_times_gen_crazy_big_sql_statement.log

