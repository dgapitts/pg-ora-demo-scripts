python3 gen_crazy_big_sql_statement.py 900 > test_900.sql
#cat test_900.sql
psql -f test_900.sql >  test_900.log
#tail -10 test_900.log
echo `grep 'Execution Time:' test_900.log | awk '{print $3}'` " 900" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_900.log | awk '{print $3}'` " 900" | tee -a plan_times_gen_crazy_big_sql_statement.log

