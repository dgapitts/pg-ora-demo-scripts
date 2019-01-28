for i in range(10001):
    print "select * from tab"+str(i)+";"
    print "select now(), pg_sleep(2);"