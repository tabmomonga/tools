#!/bin/bash
# by Hiromasa YOSHIMOTO

BIN=`dirname $0`
BIN=`readlink -f $BIN`
BIN=${BIN:-.}

if [ $# -eq 0 ]; then
	cat<<EOF > /dev/stderr
usage:
	$0  package [...]
EOF
	exit 1
fi


LOG=`mktemp /tmp/$$.XXXXXXXX` || exit 1

# returns 0 if make has failed.
function step1
{
    $BIN/step1_make_patch.sh 2>&1 > $LOG
    grep "^make:.*Error" $LOG  > /dev/null
   
    # grep returns 0 if pattern is found
    return $?
}

function process
{
    loop=0
    echo "step1  "
    while loop=`expr $loop + 1`; [ $loop -lt $max_loop ] &&step1; do
	echo "try$loop"
    done

    if [ ! $loop -lt $max_loop ]; then
	echo "FAILED:  $1"
	return
    fi

    # success

    $BIN/step2_gendiff.sh
    $BIN/step3_update_spec.sh $1
}

max_loop=20

while [ -n "$1" ]; do
    if [ -d $1/BUILD -a -f $1/$1.spec ]; then	
	(cd $1; process $1.spec)
    fi
    shift
done

rm $LOG
