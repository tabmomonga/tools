#! /bin/env python

import sqlite3
import specParse
import DEFFILE
import os

# list up all packages
pkglist = []
for pkg in os.listdir(DEFFILE.PKGDIR):
    if os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, pkg + '.spec')):
        pkglist.append(pkg)
    pkglist.sort()
        
# create db
dbName = 'depend.db'
conn = sqlite3.connect(dbName)
c = conn.cursor()
try:
    c.execute('''create table depend
              (id integer, pkg text, depPkg text)''')
except:
    c.execute("delete from depend")
    conn.commit()

# add all dependency
id = 0
for pkg in pkglist:
    print id, pkg

    depPackage = []
    spec = open(os.path.join(DEFFILE.PKGDIR, pkg, pkg + '.spec'))
    for content in spec.readlines():
        if not content.lower().startswith('buildrequires:') and \
                not content.lower().startswith('buildprereq:'):
            continue
        elif content.startswith('%prep'):
            break
        else:
            while content.endswith('\\'):
                nextLine = spec.readline()
                if not nextline.startswith('#'):
                    content += spec.readline()
            reqList = content.split(':')[1]
            for reqPkgs in reqList.split(','):
                depPackage.append(reqPkgs.strip().split(' ')[0])
    spec.close()

    for depend in depPackage:
        vt = (id, pkg, depend)
        c.execute('insert into depend values (?, ?, ?)', vt)
        id += 1

# close db
conn.commit()
conn.close()
