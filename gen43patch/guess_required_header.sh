#!/bin/sh
#
# Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

if [ $# -ne 1 ] ; then
    cat<<EOF > /dev/stderr
usage:
    $0   function
EOF
    exit 1
fi

man $1 2> /dev/null | colcrt  \
    | grep "#include <.*>" \
    | sed -e 's,#include,,' -e 's,<,,' -e 's,>,,' -e 's,[ ]*,,' \
    | sort | uniq 

exit 0