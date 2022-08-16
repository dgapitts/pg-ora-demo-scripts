modnumber=$1
batchsize=$2
numbatches=$3
scriptname=`basename "$0"|sed 's/.sh//'`
logfile="logs/${scriptname}_batchsize${batchsize}_mod${modnumber}_numbatches${numbatches}_`date +"%y%m%d-%H%M%S"`.log"
echo $logfile
uptime | tee -a $logfile

for  (( j=0; j<${numbatches}; j++ )); 
do
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="'ff80_100','ff90_100','ff100_100'" -f index_bloat.sql        >>  $logfile
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="'ff80_100','ff90_100','ff100_100'" -f hot_update_stats.sql   >>  $logfile
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="ff80_100" -v vMod=${modnumber} -v vNumRows=${batchsize} -f ff_HOT_update.sql  >>  $logfile
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="ff90_100" -v vMod=${modnumber} -v vNumRows=${batchsize} -f ff_HOT_update.sql  >>  $logfile
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="ff100_100" -v vMod=${modnumber} -v vNumRows=${batchsize} -f ff_HOT_update.sql >>  $logfile
done 

psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="'ff80_100','ff90_100','ff100_100'" -f index_bloat.sql        >>  $logfile
psql -p 5432 -d fillfactor -v vSchema="'test100k'" -v vTable="'ff80_100','ff90_100','ff100_100'" -f hot_update_stats.sql   >>  $logfile

avg_ff100_100=`grep 'Insert on\|Subquery Scan on' $logfile | grep ff100_100|cut -d '.' -f 8,16|sed 's/\./-/g'|bc | awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'`
avg_ff90_100=`grep 'Insert on\|Subquery Scan on' $logfile | grep ff90_100|cut -d '.' -f 8,16|sed 's/\./-/g'|bc | awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'`
avg_ff80_100=`grep 'Insert on\|Subquery Scan on' $logfile | grep ff80_100|cut -d '.' -f 8,16|sed 's/\./-/g'|bc | awk '{ sum += $1 } END { if (NR > 0) print sum / NR }'`
echo "avgtimes ff100-ff90-ff80: "$avg_ff100_100" "$avg_ff90_100" "$avg_ff80_100 >> $logfile
echo "avgtimes ff100-ff90-ff80: "$avg_ff100_100" "$avg_ff90_100" "$avg_ff80_100 

uptime | tee -a $logfile
