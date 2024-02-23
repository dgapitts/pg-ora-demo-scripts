python3 gen_crazy_big_sql_statement.py 1700 > test_1700.sql
#cat test_1700.sql
psql -f test_1700.sql >  test_1700.log
#tail -10 test_1700.log
echo `grep 'Execution Time:' test_1700.log | awk '{print $3}'` " 1700" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1700.log | awk '{print $3}'` " 1700" | tee -a plan_times_gen_crazy_big_sql_statement.log

