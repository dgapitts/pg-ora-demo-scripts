python3 gen_crazy_big_sql_statement.py 600 > test_600.sql
#cat test_600.sql
psql -f test_600.sql >  test_600.log
#tail -10 test_600.log
echo `grep 'Execution Time:' test_600.log | awk '{print $3}'` " 600" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_600.log | awk '{print $3}'` " 600" | tee -a plan_times_gen_crazy_big_sql_statement.log

