#! /bin/env python

import DEFFILE
import os
from optparse import OptionParser
import gettext
import locale

try:
    locale.setlocale(locale.LC_ALL, '')
    gettext.bindtextdomain(DEFFILE.PACKAGE, DEFFILE.locale_dir)
    gettext.textdomain(DEFFILE.PACKAGE)
    gettext.install(DEFFILE.PACKAGE, DEFFILE.locale_dir, unicode=1)
except:
    pass

parser = OptionParser()
parser.add_option("-m", "--main",
                  default=False, action="store_true", dest="show_main",
                  help=_("list up main packages"))
parser.add_option("-a", "--alter",
                  default=False, action="store_true", dest="show_alter",
                  help=_("list up Alter packages"))
parser.add_option("-n", "--nonfree",
                  default=False, action="store_true", dest="show_nonfree",
                  help=_("list up Nonfree packages"))
parser.add_option("-o", "--orphan",
                  default=False, action="store_true", dest="show_orphan",
                  help=_("list up Orphan package"))
parser.add_option("-s", "--skip",
                  default=False, action="store_true", dest="show_skip",
                  help=_("list up SKIP package"))
(opt, args) = parser.parse_args()

pkglist = []
for pkg in os.listdir(DEFFILE.PKGDIR):
    if os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, pkg + '.spec')):
        pkglist.append(pkg)
    pkglist.sort()

main = []
alter = []
nonfree = []
orphan = []
skip = []
for pkg in pkglist:
    if os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, 'TO.Alter')):
        alter.append(pkg)
    elif os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, 'TO.Nonfree')):
        nonfree.append(pkg)
    elif os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, 'TO.Orphan')):
        orphan.append(pkg)
    elif os.path.exists(os.path.join(DEFFILE.PKGDIR, pkg, '.SKIP')):
        skip.append(pkg)
    else:
        main.append(pkg)

if opt.show_main:
    for pkg in main:
        print pkg
if opt.show_alter:
    for pkg in alter:
        print pkg
if opt.show_nonfree:
    for pkg in nonfree:
        print pkg
if opt.show_orphan:
    for pkg in orphan:
        print pkg
if opt.show_skip:
    for pkg in skip:
        print pkg
