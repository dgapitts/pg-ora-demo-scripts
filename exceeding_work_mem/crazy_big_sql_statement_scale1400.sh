python3 gen_crazy_big_sql_statement.py 1400 > test_1400.sql
#cat test_1400.sql
psql -f test_1400.sql >  test_1400.log
#tail -10 test_1400.log
echo `grep 'Execution Time:' test_1400.log | awk '{print $3}'` " 1400" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1400.log | awk '{print $3}'` " 1400" | tee -a plan_times_gen_crazy_big_sql_statement.log

