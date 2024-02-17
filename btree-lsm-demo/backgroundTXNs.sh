#v1 simple logging to /tmp and reuse
sleepSeconds=$1
sleepIterations=$2
logfile='/tmp/backgroundTXN.log'

echo "sc${sleepSeconds}_si${sleepIterations}" > ${logfile}

for ((i = 1; i <= "${sleepIterations}"; i++ )); do 
    date | tee -a  ${logfile}
    psql -t -c "begin; select txid_current();select pg_sleep(${sleepSeconds});end" >> ${logfile}
done