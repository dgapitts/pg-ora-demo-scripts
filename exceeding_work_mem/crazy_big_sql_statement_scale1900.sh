python3 gen_crazy_big_sql_statement.py 1900 > test_1900.sql
#cat test_1900.sql
psql -f test_1900.sql >  test_1900.log
#tail -10 test_1900.log
echo `grep 'Execution Time:' test_1900.log | awk '{print $3}'` " 1900" | tee -a exec_times_gen_crazy_big_sql_statement.log
echo `grep 'Planning Time:' test_1900.log | awk '{print $3}'` " 1900" | tee -a plan_times_gen_crazy_big_sql_statement.log

