python3 gen_crazy_big_sql_statement.py 100 > test_100.sql
#cat test_100.sql
psql -f test_100.sql >  test_100.log
#tail -10 test_100.log
echo `grep 'Execution Time:' test_100.log | awk '{print $3}'` " 100" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_100.log | awk '{print $3}'` " 100" | tee -a plan_times_gen_crazy_big_sql_statement.log

