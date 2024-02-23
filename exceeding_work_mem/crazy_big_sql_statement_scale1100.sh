python3 gen_crazy_big_sql_statement.py 1100 > test_1100.sql
#cat test_1100.sql
psql -f test_1100.sql >  test_1100.log
#tail -10 test_1100.log
echo `grep 'Execution Time:' test_1100.log | awk '{print $3}'` " 1100" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1100.log | awk '{print $3}'` " 1100" | tee -a plan_times_gen_crazy_big_sql_statement.log

