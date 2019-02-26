import psycopg2,time
try:
    conn = psycopg2.connect("dbname='bench1' user='bench1' host='localhost' password='changeme'")
except:
    print "I am unable to connect to the database"
cur = conn.cursor()
cur.execute("CREATE TABLE test_mvcc (id serial PRIMARY KEY, num integer, data varchar);")
for i in range(1,100000):
  cur.execute("insert into test_mvcc values (%s,%s,%s)",(i,i,"blah blah blah blah blah blah ..................."))
  offset=i-1000
  conn.commit()
cur.close()
conn.close()
