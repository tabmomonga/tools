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
    c.execute('''create table subPkg
              (id integer, pkg text, subPkg text)''')
except:
    c.execute("delete from depend")
    c.execute("delete from subPkg")
    conn.commit()

# add all dependency
id = 0
ids = 0
for pkg in pkglist:
    depPackage = []
    subPackage = []
    macros = {'name':pkg}
    spec = open(os.path.join(DEFFILE.PKGDIR, pkg, pkg + '.spec'))
    for content in spec.readlines():
        if content.startswith('%prep'):
            break
        elif content.startswith('%defile') or content.startswith('%global'):
            contentList = content.split()
            macroName = ''
            for cont in contentList[1:]:
                if cont != ' ':
                    if macroName == '':
                        macroName = cont
                    else:
                        macroData = cont
            macros[macroName] = macroData
        elif content.startswith('%package'):
            for macro in macros.iterkeys():
                content = content.replace('%{' + macro + '}', macros[macro])
            contentList = content.split()
            if contentList[1] == '-n':
                subPackage.append(contentList[2])
            else:
                subPackage.append(pkg + '-' + contentList[1])
        elif content.lower().startswith('buildrequires:') or \
                content.lower().startswith('buildprereq:'):
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
    for subPkg in subPackage:
        vt = (id, pkg, subPkg)
        c.execute('insert into subPkg values (?, ?, ?)', vt)
        ids += 1

# close db
conn.commit()
conn.close()
