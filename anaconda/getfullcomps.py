#!/usr/bin/python2.3

import os,sys,string
import time


try:
    import rpm404 as rpm
except ImportError:
    import rpm

filename = ''
path = ''
arch = ''

try:
    import rhpl.comps as comps
except ImportError:
    sys.path.append('/usr/local/bin')
    import comps

def usage():
    sys.stderr.write("%s <comps file> <path to tree> <arch>\n" %
                     (sys.argv[0],))

def readAndMergeHeaderList(path, arch):
    hdlist = rpm.readHeaderListFromFile("%s/%s/Momonga/base/hdlist" % (path, arch))
    fd = os.open("%s/%s/Momonga/base/hdlist2" % (path, arch), os.O_RDONLY)
    rpm.mergeHeaderListFromFD(hdlist, fd, 1000004)
    os.close(fd)

    return hdlist

def main():
    hdlist = readAndMergeHeaderList(path, arch)
    hddict = {}
    providesDict = {}
    nopackage = []
    brokendep = []
    
    for h in hdlist:
        h.fullFilelist()
        hddict[h['name']] = h
        for prov in h[rpm.RPMTAG_PROVIDES]:
            # handling of multiple provides.  pretty much a hack
            if providesDict.has_key(prov):
                # sendmail is preferred over postfix
                if providesDict[prov] == "sendmail" and h['name'] == "postfix":
                    continue
                if providesDict[prov] == "postfix" and h['name'] == "sendmail":
                    pass
                # if what we have in the providesDict is a -devel and
                # what we're looking at now isn't, prefer the non-devel
                elif (providesDict[prov].endswith('-devel') and
                      not h['name'].endswith('-devel')):
                    pass
                # and vice versa
                elif (h['name'].endswith('-devel') and 
                      not providesDict[prov].endswith('-devel')):
                    continue
                # else to multiple provides -- shorter name wins
                # this handles glibc-debug, kernel-*, kde2-compat, mod_perl...
                elif (providesDict.has_key(prov) and
                      len(providesDict[prov]) < len(h['name'])):
                    continue
            providesDict[prov] = h['name']

    compslist = comps.Comps("%s/%s/Momonga/base/%s" % (path, arch, filename))

    everything = comps.Group(compslist)
    for h in hdlist:
        everything.packages[h['name']] = (None, h['name'])

    packages = {}
    founddeps = {}
    groups = compslist.groups.keys()
    groups.sort()
    compslist.groups['Everything'] = everything
    groups.append('Everything')
    for groupname in groups:
        group = compslist.groups[groupname]
#    for group in compslist.groups.values():
#    group = compslist.groups['Base']
#    if 1:
        new = []
        
        for (options, pkgname) in group.packages.values():
            if pkgname in packages.keys():
                # we've already found this package's dependencies
                continue

            new.append(pkgname)

        while len(new) > 0:
            pkgs = new
            pkgs.sort()
#            print >> sys.stderr, pkgs
            new = []
            for name in pkgs:
                # bail because we have no chance of this working
                if not hddict.has_key(name):
                    nopackage.append("CRITICAL ERROR: Unable to find package %s" % (name,))
                    continue
##                     raise RuntimeError, ("CRITICAL ERROR: Unable to find "
##                                          "package %s" %(name,))

                hdr = hddict[name]
                deps = []

                # FIXME: we should probably verify versions here
                # let's resolve dependencies
                for req in hdr[rpm.RPMTAG_REQUIRENAME]:
                    # have to assume that rpmlib deps will just work
                    if req.startswith('rpmlib('):
                        continue

                    # we already have this package in our deps
                    if req in deps:
                        #print >> sys.stderr, "already found %s for %s" %(req, name)
                        continue

                    # we've looked for this dependency before, fastpath
                    if req in founddeps.keys():
                        #print >> sys.stderr, "already looked for %s" %(req,)
                        thedep = founddeps[req]
                        if thedep not in deps:
                            deps.append(thedep)
                        continue

                    # I provide my own dependency
                    if (req in hdr[rpm.RPMTAG_PROVIDENAME] or
                        req in hdr[rpm.RPMTAG_FILENAMES]):
                        continue

                    # this package is in the hdr list
                    if hddict.has_key(req):
                        #print >> sys.stderr, "in the headerlist"
                        deps.append(req)
                        continue

                    if req in providesDict.keys():
                        #print >> sys.stderr, "found %s in the provDict" %(req,)
                        thedep = providesDict[req]
                        if thedep not in deps:
                            deps.append(thedep)
                        continue

                    # now we have to look through all of the packages
                    found = 0
                    #print >> sys.stderr, "wow this will suck (%s)" %(req,)
                    for h in hddict.values():
                        if found == 1:
                            break
                        for tag in [rpm.RPMTAG_FILENAMES]:
##                         for tag in [rpm.RPMTAG_PROVIDENAME,
##                                     rpm.RPMTAG_FILENAMES]:
                            if req in h[tag]:
                                # XXX ignore glibc-debug and non base
                                # kernels for now with dep resolve
                                if (h['name'] == "glibc-debug" or
                                    h['name'].startswith("kernel-")):
                                    continue
                                if h['name'] not in deps:
                                    deps.append(h['name'])
                                    founddeps[req] = h['name']
                                found = 1
                                break
                    if found == 1:
                        continue

                    # ack, I haven't found anything for this dep. scream loudly
                    brokendep.append("CRITICAL ERROR: Unable to resolve dependency %s for %s" % (req, name))

                packages[name] = deps
                for dep in deps:
                    if (dep not in packages.keys() and
                        dep not in new and dep not in pkgs):
                        new.append(dep)

    # FIXME: I need to check every package I haven't already looked at
    # for missing deps

    # use this so that we can return something instead of just printing to stdout
    pkgsxml = []
    for pkgname in packages.keys():
        deps = packages[pkgname]
        
        pkgsxml.append("  <package>")
        pkgsxml.append("    <name>%s</name>" % (pkgname,))
        pkgsxml.append("    <dependencylist>")
        for dep in deps:
            pkgsxml.append("      <dependency>%s</dependency>" % (dep,))
        pkgsxml.append("    </dependencylist>")
        pkgsxml.append("  </package>")
    return pkgsxml, nopackage, brokendep

if __name__ == "__main__":
    if len(sys.argv) < 4:
        usage()
        sys.exit(1)
    filename = sys.argv[1]
    path = sys.argv[2]
    arch = sys.argv[3]
    mypkgxml, nopackage, brokendep = main()

    for i in range(0, len(mypkgxml)):
        print mypkgxml[i]

    if len(nopackage) > 0:
        for i in range(0, len(nopackage)):
            print >> sys.stderr, "%s" % nopackage[i]

    if len(brokendep) > 0:
        for i in range(0, len(brokendep)):
            print >> sys.stderr, "%s" % brokendep[i]
