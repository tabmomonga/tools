#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=`readlink -f $BIN`
BIN=${BIN:-.}

cd BUILD || exit 1

for dir in *; do
    [ -d $dir ] || continue
    (cd $dir && $BIN/make_gcc46_patch.sh)
done

exit 0
