#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=`readlink -f $BIN`
BIN=${BIN:-.}

LANG=C 


cd BUILD || exit 1

for dir in *; do
    [ -d $dir ] || continue
    gendiff $dir .gcc45~  > $dir-gcc45.patch
done

cd ..

echo 
echo " genereated file(s) :"
echo
ls -la  BUILD/*gcc45.patch
echo

exit 
