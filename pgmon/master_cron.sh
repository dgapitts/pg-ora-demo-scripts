# Master monitoring cron job for scheduling postgres monitoring

cd ~/pg-ora-demo-scripts/logs

#setup log file names
NOW=$(date +"%m-%d-%Y.%H%M")
echo "all logs file to be created under logs/$NOW.monitor-file-name.log"
active_session_log="$NOW.active_sessions.log"
top_query_text_log="$NOW.top_query_text.log"
top_query_elapsed_log="$NOW.top_query_elapsed.log"
top_query_calls_log="$NOW.top_query_calls.log"
non_default_parameters_log="$NOW.non_default_parameters.log"
block_sess_mon_log="$NOW.block_sess_mon.log"

# reset pg_stat_summary
time psql -h localhost -U postgres -p 5432 -f pgmon/pg_stat_summary_reset.sql

#gather active session details every 10 session
iterations=`echo $1*6|bc`
echo $iterations
for i in `seq 1 $iterations`;
do 
   time psql -h localhost -U postgres -p 5432 -f pgmon/pg_act_query.sql | tee -a $active_session_log
   time psql -h localhost -U postgres -p 5432 -f pgmon/block_sess_mon.sql | tee -a $block_sess_mon_log
   sleep 10
   #sleep 1   # only useful for pgmon.sh script testing/develop
done

#gather pg_stat_statements details at the end of the monitoring window
psql -h localhost -U postgres -p 5432 -f pgmon/pg_top_query_elapsed.sql > $top_query_elapsed_log
psql -h localhost -U postgres -p 5432 -f pgmon/pg_top_query_calls.sql > $top_query_calls_log
psql -h localhost -U postgres -p 5432 -f pgmon/pg_top_query_text.sql > $top_query_text_log
psql -h localhost -U postgres -p 5432 -f pgmon/pg_non_default_parameters.sql > $non_default_parameters_log


#gzip up log files
#ls -l 
#time gzip $NOW*log
#ls -l 
