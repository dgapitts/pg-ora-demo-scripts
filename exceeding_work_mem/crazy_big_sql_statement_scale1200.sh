python3 gen_crazy_big_sql_statement.py 1200 > test_1200.sql
#cat test_1200.sql
psql -f test_1200.sql >  test_1200.log
#tail -10 test_1200.log
echo `grep 'Execution Time:' test_1200.log | awk '{print $3}'` " 1200" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1200.log | awk '{print $3}'` " 1200" | tee -a plan_times_gen_crazy_big_sql_statement.log

