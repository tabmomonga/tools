#! /bin/env python

import DEFFILE
import os
import rpm
import specParse

class buildList:
    def __init__(self, dir = DEFFILE.PKGDIR, opt = {}, pkgs = []):
        self.buildList = []
        self.dir = dir
        self.pkgs = pkgs
        if self.pkgs == []:
            self.pkgs = os.listdir(dir)
        if opt.main:
            self.alter = False
            self.nonfree = False
            self.orphan = False
        else:
            self.alter = opt.alter
            self.nonfree = opt.nonfree
            self.orphan = opt.orphan

    def isBuild(self, pkg):
        pkgPath = os.path.join(self.dir, pkg)
        specFileName = os.path.join(pkgPath, pkg + '.spec')
        if os.path.exists(specFileName):
            srpmFileName = specParse.specParse(specFileName).getSrpmName()
            if os.path.exists(os.path.join(pkgPath, 'TO.Alter')):
                if self.alter:
                    if os.path.exists(os.path.join(DEFFILE.TOPDIR + '-Alter', SRPMS, srpmFileName)):
                        return False
                    else:
                        return True
                else:
                    return False
            elif os.path.exists(os.path.join(pkgPath, 'TO.Nonfree')):
                if self.nonfree:
                    if os.path.exists(os.path.join(DEFFILE.TOPDIR + '-Nonfree', SRPMS, srpmFileName)):
                        return False
                    else:
                        return True
                else:
                    return False
            elif os.path.exists(os.path.join(pkgPath, 'TO.Orphan')):
                if self.orphan:
                    if os.path.exists(os.path.join(DEFFILE.TOPDIR + '-Orphan', SRPMS, srpmFileName)):
                        return False
                    else:
                        return True
                else:
                    return False
            elif os.path.exists(os.path.join(pkgPath, '.SKIP')):
                return False
            else:
                if os.path.exists(os.path.join(DEFFILE.TOPDIR, srpmFileName)):
                    return False
                else:
                    return True

    def addBuildList(self):
        for pkg in self.pkgs:
            if self.isBuild(pkg):
                self.buildList.append(pkg)
        return self.buildList

if __name__ == "__main__":
    import optionParse
    import sys
    op = optionParse.optionParse()
    bl = buildList(DEFFILE.PKGDIR, op.opt, sys.argv[1:])
    print bl.addBuildList()
