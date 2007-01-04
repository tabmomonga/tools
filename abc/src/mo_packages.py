#! /bin/env python

import DEFFILE
import os
import mo_option

def mo_packages(dir, args):
    pkglist = []
    if not args == []:
        for pkg in args:
            if os.path.exists(os.path.join(dir, pkg, pkg + '.spec')):
                pkglist.append(pkg)
    else:
        for pkg in os.listdir(dir):
            if os.path.exists(os.path.join(dir, pkg, pkg + '.spec')):
                pkglist.append(pkg)
    pkglist.sort()

    main = []
    alter = []
    nonfree = []
    orphan = []
    skip = []
    for pkg in pkglist:
        if os.path.exists(os.path.join(dir, pkg, 'TO.Alter')):
            alter.append(pkg)
        elif os.path.exists(os.path.join(dir, pkg, 'TO.Nonfree')):
            nonfree.append(pkg)
        elif os.path.exists(os.path.join(dir, pkg, 'TO.Orphan')):
            orphan.append(pkg)
        elif os.path.exists(os.path.join(dir, pkg, '.SKIP')):
            skip.append(pkg)
        else:
            main.append(pkg)
    return (main, alter, nonfree, orphan, skip)

if __name__ == "__main__":
    (opt, args) = mo_option.mo_option()
    (main, alter, nonfree, orphan, skip) = mo_packages(DEFFILE.PKGDIR, args)
    print main
    print alter
    print nonfree
    print orphan
    print skip
