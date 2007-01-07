#!/bin/sh
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

##debug=echo

function error()
{	
    echo $@
    exit -1
}


function add_queue()
{
    FILE=$1
    [ -f $FILE ] || error "no queue file."
    shift
    
    while [ -n "$1" ]; do
	for x in $1; do
	    if [ -d $x ] ; then
		echo `basename $x` >> $FILE
	    fi
	done
	shift
    done	
}

function build_queue ()
{
    [ -f $1 ] || error "[$1] is not queue file"
    
    LINE=`cat $1 |wc -l `
    if [ 0 -ne $LINE ]; then
	$debug ../tools/OmoiKondara `cat $1`
	
	cat /dev/null >  $1
    fi
}

function remove_pkg()
{
    echo "remove pkg $@"
}

function touch_pkg()
{
    while [ -n "$1" ]; do
	[ -f $1.spec ] && $debug touch $1.spec
	shift
    done
}

function update ()
{
    $debug ../tools/update-mph
    $debug sudo mph-get -f upgrade
}
function execute_list()
{
    while read line; do
	case $line  in
	    REMOVE*)
		build_queue  $QUEUE
		for x in `echo $line | sed 's,REMOVE,,g'`; do
		    remove_pkg $x
		done
		;;
	    UP)
		build_queue  $QUEUE
		update
		;;
	    TOUCH*)
		build_queue  $QUEUE
		for x in `echo $line | sed 's,TOUCH,,g'`; do
		    touch_pkg $x	
		done
		;;
	    *)
		add_queue $QUEUE $line
		;;
	esac
    done
}

function parse_list ()
{
    QUEUE=`mktemp /tmp/build_sh_XXXXXX` || error "failed to mktemp"

    while [ -n "$1" ]; do
	if [ "-" == $1 ]; then
	    cat /dev/stdin | grep -v "^#" | execute_list
	else
	    cat $1 | grep -v "^#" | execute_list
	fi
	shift
    done
    
    build_queue $QUEUE

    rm $QUEUE
}

parse_list $@
