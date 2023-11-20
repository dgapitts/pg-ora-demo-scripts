rm  *_times_gen_crazy_big_sql_statement.log

for i in {2..20}
do
  size=$((i))00;sed "s/100/$size/g" ./crazy_big_sql_statement_scale100.sh | tee ./crazy_big_sql_statement_scale$size.sh
  bash ./crazy_big_sql_statement_scale$size.sh
done

echo "final results";head -100 *_times_gen_crazy_big_sql_statement.log

