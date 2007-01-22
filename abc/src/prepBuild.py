#! /bin/env python

import os
import DEFFILE
import specParse
import shutil
import urllib
import urlparse

class prepBuild:
    def __init__(self, pkg):
        self.pkg = pkg
        self.cwd = os.path.join(DEFFILE.PKGDIR, pkg)
        os.chdir(self.cwd)
        self.spec = specParse.specParse(os.path.join(self.cwd, pkg + '.spec'))
        self.createDirs()
    def createDirs(self):
        dirs = ['RPMS', 'SRPMS', 'SOURCES', 'BUILD']
        for d in dirs:
            try:
                os.mkdir(d)
            except OSError:
                print "Cannot Create Directory"
    def placeSourcePatch(self):
        srcdir = os.path.join(self.cwd, 'SOURCES')
        for source in self.spec.getSources() + self.spec.getPatches():
            shutil.copy(source, os.path.join(srcdir,source))
    def placeNoSourcePatch(self):
        srcdir = os.path.join(self.cwd, 'SOURCES')
        for source in self.spec.getNoSources() + self.spec.getNoPatches():
            filename = urlparse.urlparse(source)[2].split('/')[-1]
            if os.path.isfile(os.path.join(DEFFILE.TOPDIR, 'SOURCES', filename)):
                shutil.copy(os.path.join(DEFFILE.TOPDIR, 'SOURCES', filename),
                            os.path.join(srcdir, filename))
            else:
                urllib.urlretrieve(source, os.path.join(srcdir, filename))
    def createMacroFile(self):
        file = open('rpmmacros', "w")
        writeString = '%%_topdir %s\n' % os.getcwd()
        writeString += '%%_arch %s\n' % DEFFILE.arch
        writeString += '%%_host_cpu %s\n' % DEFFILE.host_cpu
        writeString += '%%_host_vender %s\n' % DEFFILE.host_vender
        writeString += '%%_host_os %s\n' % DEFFILE.host_os
        writeString += '%%_numjobs %s\n' % DEFFILE.numjobs
        writeString += '%%_arch %s\n' % DEFFILE.arch
        writeString += '%smp_mflags -j%{_numjobs}\n'
        writeString += '%_smp_mflags -j%{_numjobs}\n'
        file.write(writeString)

        # we need more macros
        file.close()

        writeFile = open('rpmrc', 'w')
        readFile = open(os.path.join('..', 'rpmrc'), 'r')
        for line in readFile.readlines():
            if not line.startswith('macrofiles:'):
                writeFile.write(line)
            else:
                writeFile.write(line.rstrip('\n') + './rpmmacros:')
        readFile.close()
        writeFile.close()
    
if __name__ == "__main__":
    import sys
    b = prepBuild(sys.argv[1])
    b.placeSourcePatch()
    b.placeNoSourcePatch()
    b.createMacroFile()
    print os.listdir(os.getcwd())
