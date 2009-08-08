#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=${BIN:-.}

LANG=C 

LOG=`mktemp /tmp/$$.XXXXXXX` || exit 1

CMD=${@:-make}

$CMD  2>&1 | tee  $LOG

gawk -vBIN=$BIN -f $BIN/sub_make_gcc44_patch.awk  $LOG


rm $LOG
