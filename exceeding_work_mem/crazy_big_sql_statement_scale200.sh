python3 gen_crazy_big_sql_statement.py 200 > test_200.sql
#cat test_200.sql
psql -f test_200.sql >  test_200.log
#tail -10 test_200.log
echo `grep 'Execution Time:' test_200.log | awk '{print $3}'` " 200" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_200.log | awk '{print $3}'` " 200" | tee -a plan_times_gen_crazy_big_sql_statement.log

