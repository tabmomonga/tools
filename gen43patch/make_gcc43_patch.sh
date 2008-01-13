#!/bin/sh
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=${BIN:-.}

LANG=C 

LOG=`mktemp /tmp/$$.XXXXXXX` || exit 1

make  2>&1 | tee  $LOG

gawk -vBIN=$BIN -f $BIN/sub_make_gcc43_patch.awk  $LOG


rm $LOG
