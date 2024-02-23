python3 gen_crazy_big_sql_statement.py 300 > test_300.sql
#cat test_300.sql
psql -f test_300.sql >  test_300.log
#tail -10 test_300.log
echo `grep 'Execution Time:' test_300.log | awk '{print $3}'` " 300" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_300.log | awk '{print $3}'` " 300" | tee -a plan_times_gen_crazy_big_sql_statement.log

