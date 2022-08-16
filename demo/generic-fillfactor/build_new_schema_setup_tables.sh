psql -p 5432 -d fillfactor -c "create schema $1"
psql -p 5432 -d fillfactor -v vSchema="'$1'" -f ff80_100.sql
psql -p 5432 -d fillfactor -v vSchema="'$1'" -f ff90_100.sql
psql -p 5432 -d fillfactor -v vSchema="'$1'" -f ff100_100.sql
