
echo "time pgbench -i -s $1 --foreign-keys"
time pgbench -i -s $1 --foreign-keys

echo "database table overview (\d+)"
psql -c "\d+"

echo "analyze database"
time psql -c "analyze"

echo "cardinality check on branches"
psql -c "explain select distinct bid from pgbench_branches ;"

echo "sample analytics query who has the most money in a branch (commercially important ... VIP customers)"
#psql -c "SELECT * FROM pg_stats WHERE tablename ='pgbench_accounts';";
echo "SELECT * FROM pg_stats WHERE tablename ='pgbench_accounts' and attname='abalance'" | psql -x
#psql -c "explain select max(abalance), aid from pgbench_accounts where bid=1";

echo "lets try adding an index to increase performance ..."
time psql -c "create index accounts_bid on pgbench_accounts(bid)";
echo "maybe time to re-analyze?"
time psql -c "analyze"

echo "account table details..."
psql -c "\d+ pgbench_accounts"

echo "let try the query again ..."
psql -c "explain select max(abalance) from pgbench_accounts where bid=1";


