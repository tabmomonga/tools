#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=${BIN:-.}

LANG=C 


cd BUILD || exit 1

for dir in *; do
    [ -d $dir ] || continue
    gendiff $dir .gcc43~  > $dir-gcc43.patch
done

cd ..

echo 
echo " genereated file(s) :"
echo
ls -la  BUILD/*gcc43.patch
echo

exit 
