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
    gendiff $dir .gtk220~  > $dir-gtk220.patch
done

cd ..

echo 
echo " genereated file(s) :"
echo
ls -la  BUILD/*gtk220.patch
echo

exit 
