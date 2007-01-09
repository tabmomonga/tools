#! /bin/env python

import sqlite3

# open db
dbName = 'depend.db'
conn = sqlite3.connect(dbName)
c = conn.cursor()
c.execute('select * from depend order by id')
for row in c:
    print row
