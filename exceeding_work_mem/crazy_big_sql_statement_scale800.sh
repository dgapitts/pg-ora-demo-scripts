python3 gen_crazy_big_sql_statement.py 800 > test_800.sql
#cat test_800.sql
psql -f test_800.sql >  test_800.log
#tail -10 test_800.log
echo `grep 'Execution Time:' test_800.log | awk '{print $3}'` " 800" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_800.log | awk '{print $3}'` " 800" | tee -a plan_times_gen_crazy_big_sql_statement.log

