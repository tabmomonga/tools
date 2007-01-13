#! /bin/env python

import DEFFILE
from optparse import OptionParser
import gettext
import locale


class optionParse:
    def __init__(self):
        try:
            locale.setlocale(locale.LC_ALL, '')
            gettext.bindtextdomain(DEFFILE.PACKAGE, DEFFILE.locale_dir)
            gettext.textdomain(DEFFILE.PACKAGE)
            gettext.install(DEFFILE.PACKAGE, DEFFILE.locale_dir, unicode=1)
        except:
            pass
        (self.opt, self.args) = self.optParse()
    def optParse(self):
        usage = _("usage:\n\t") + \
            DEFFILE.PACKAGE + "\t[option] packages"
        parser = OptionParser(usage=usage, version=DEFFILE.VERSION)
        # mandatory options
        parser.add_option("-n", "--nonfree",
                          default=False, action="store_true", dest="nonfree",
                          help=_("build Nonfree package, too"))
        parser.add_option("-O", "--orphan",
                          default=False, action="store_true", dest="orphan",
                          help=_("build Orphan package, too"))
        parser.add_option("-L", "--alter",
                          default=False, action="store_true", dest="alter",
                          help=_("build Alter(alternative) package, too"))
        parser.add_option("-m", "--main",
                          default=False, action="store_true", dest="main",
                          help=_("main package only"))
        # convenience options
#        parser.add_option("-r", "--rpmopt", metavar="RPMOPTS",
#                          dest="rpmopt",
#                          help=_("specify option through to rpm"))
#        parser.add_option("-f", "--force",
#                          default=False, action="store_true", dest="force",
#                          help=_("force build"))
#        parser.add_option("-i", "--install",
#                          default=False, action="store_true", dest="install",
#                          help=_("force install after build (except kernel and usolame)"))
#        parser.add_option("-s", "--script",
#                          default=False, action="store_true", dest="script",
#                          help=_("script mode"))
#        parser.add_option("-v", "--verbose",
#                          default=False, action="store_true", dest="verbose",
#                          help=_("verbose mode"))
#        parser.add_option("-G", "--debug",
#                          default=False, action="store_true", dest="debug",
#                          help=_("enable debug flag"))
#        parser.add_option("-M", "--mirrorfirst",
#                          default=False, action="store_true", dest="mirrorfirst",
#                          help=_("download from mirror first"))

        # ignored options
#        parser.add_option("-N", "--nostrict",
#                          default=False, action="store_true", dest="nostrict",
#                          help=_("proceed by old behavior"))
#        parser.add_option("-R", "--ignore-remove",
#                          default=False, action="store_true", dest="remove",
#                          help=_("do not uninstall packege if REMOVE.* exists"))
#        parser.add_option("-S", "--scanpackages",
#                          default=False, action="store_true", dest="scanpackage",
#                          help=_("execute mph-scanpackage"))
#        parser.add_option("-C", "--noccache",
#                          default=False, action="store_true", dest="noccache",
#                          help=_("no ccache"))
#        parser.add_option("-1", "--cachecc1",
#                          default=False, action="store_true", dest="cachecc1",
#                          help=_("use cachecc1"))
#        parser.add_option("-D", "--distcc",
#                          default=False, action="store_true", dest="distcc",
#                          help=_("enable to use distcc"))

        # obsolete options
#        parser.add_option("-a", "--archdep",
#                          default=False, action="store_true", dest="noarch",
#                          help=_("ignore noarch packages"))
#        parser.add_option("-A", "--arch", metavar="ARCH",
#                          dest="arch",
#                          help=_("specify architecture"))
#        parser.add_option("-c", "--cvs",
#                          default=False, action="store_true", dest="cvs",
#                          help="ignored. remained for compatibility")
#        parser.add_option("-d", "--depend", metavar="DEPENDS",
#                          dest="depends",
#                          help=_("specify dependencies"))
#        parser.add_option("-g", "--checkgroup",
#                          default=False, action="store_true", dest="group",
#                          help=_("group check only"))
#        parser.add_option("-z", "--zoo",
#                          default=False, action="store_true", dest="zoo",
#                          help=_("build Zoo package, too"))
        return parser.parse_args()


if __name__ == "__main__":
    opt = optionParse()
    print opt.opt
    print opt.args
