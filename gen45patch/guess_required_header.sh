#!/bin/bash
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

case "$1" in
EXIT_SUCCESS)
	echo stdlib.h
	;;
*int64_t|*int32_t)
	echo stdint.h
	;;
*INT_MAX|*INT_MIN|*LONG_MAX|*LONG_MIN|*CHAR_MAX|*CHAR_MIN|PATH_MAX)
	echo limits.h
	;;
std::time_t)
	echo ctime
	;;
auto_ptr)
	echo memory
	;;
numeric_limits)
	echo limits
	;;
abs|find_if|min|max|transform|count|reverse)
	echo algorithm
	;;
*)
man 3 $1 2> /dev/null | colcrt  \
    | grep "#include <.*>" \
    | sed -e 's,#include,,' -e 's,<,,' -e 's,>,,' -e 's,[ ]*,,' \
    | sort | uniq 
	;;
esac
exit 0
