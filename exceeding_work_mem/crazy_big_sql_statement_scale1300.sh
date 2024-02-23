python3 gen_crazy_big_sql_statement.py 1300 > test_1300.sql
#cat test_1300.sql
psql -f test_1300.sql >  test_1300.log
#tail -10 test_1300.log
echo `grep 'Execution Time:' test_1300.log | awk '{print $3}'` " 1300" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1300.log | awk '{print $3}'` " 1300" | tee -a plan_times_gen_crazy_big_sql_statement.log

