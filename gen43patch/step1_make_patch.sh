#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=${BIN:-.}

cd BUILD || exit 1

for dir in *; do
    [ -d $dir ] || continue
    (cd $dir && $BIN/make_gcc43_patch.sh)
done

exit 0
