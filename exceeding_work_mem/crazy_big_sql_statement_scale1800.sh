python3 gen_crazy_big_sql_statement.py 1800 > test_1800.sql
#cat test_1800.sql
psql -f test_1800.sql >  test_1800.log
#tail -10 test_1800.log
echo `grep 'Execution Time:' test_1800.log | awk '{print $3}'` " 1800" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1800.log | awk '{print $3}'` " 1800" | tee -a plan_times_gen_crazy_big_sql_statement.log

