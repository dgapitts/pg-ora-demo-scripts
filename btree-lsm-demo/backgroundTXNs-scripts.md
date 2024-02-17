# backgroundTXNs scripts

Initial version with simple logging to /tmp (and reused every run)

```
davidpitts@Davids-MacBook-Pro btree-lsm-demo % cat backgroundTXNs.sh
#v1 simple logging to /tmp and reuse
sleepSeconds=$1
sleepIterations=$2
logfile='/tmp/backgroundTXN.log'

echo "sc${sleepSeconds}_si${sleepIterations}" > ${logfile}

for ((i = 1; i <= "${sleepIterations}"; i++ )); do
    date | tee -a  ${logfile}
    psql -t -c "begin; select txid_current();select pg_sleep(${sleepSeconds});end" >> ${logfile}
done%
```


here is the output
```
davidpitts@Davids-MacBook-Pro paris % bash backgroundTXNs.sh 2 3;echo "\nDONE...";cat /tmp/backgroundTXN.log
Sat Feb 17 16:30:18 CET 2024
Sat Feb 17 16:30:20 CET 2024
Sat Feb 17 16:30:22 CET 2024

DONE...
sc2_si3
Sat Feb 17 16:30:18 CET 2024
BEGIN
        61925



COMMIT
Sat Feb 17 16:30:20 CET 2024
BEGIN
        61926



COMMIT
Sat Feb 17 16:30:22 CET 2024
BEGIN
        61927



COMMIT
```
