python3 gen_crazy_big_sql_statement.py 1600 > test_1600.sql
#cat test_1600.sql
psql -f test_1600.sql >  test_1600.log
#tail -10 test_1600.log
echo `grep 'Execution Time:' test_1600.log | awk '{print $3}'` " 1600" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1600.log | awk '{print $3}'` " 1600" | tee -a plan_times_gen_crazy_big_sql_statement.log

