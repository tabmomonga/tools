#! /bin/env python
import rpm

def getSrpmName(specFileName):
    ts = rpm.ts()
    spec = ts.parseSpec(specFileName)
    header = spec.header()
    soueces = spec.sources()
    suffix = '.src.rpm'
    for src in soueces:
        if src[2] == 9:
            suffix = '.nosrc.rpm'
    srpmName = header[rpm.RPMTAG_NAME] + '-' + \
        header[rpm.RPMTAG_VERSION] + '-' + \
        header[rpm.RPMTAG_RELEASE] + \
        suffix
    return srpmName

if __name__ == "__main__":
    import sys

    try:
        print getSrpmName(sys.argv[1])
    except:
        print "USAGE: ./mo_get_srpm_name.py specfile"
