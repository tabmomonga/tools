#!/bin/bash
#
#
# test version 
# 
# Hiromasa YOSHIMOTO <y@momonga-linux.org>
#
#
#  output format is "PKGNAME","REVISION","STATUS_STRING"


export LANG=C


SEP=","                   # field separator
unset WITHOUT_REVISION
unset WITHOUT_SUCCESS
progress=-1               # output progress bar when >= 0
unset DEBUG

function error 
{
    echo "$0: " $@ > /dev/stderr
    exit 1
}

function debug
{
    [ -n "$DEBUG" ] && echo "   " $@ > /dev/stderr
}


function usage
{
    cat<<EOF
usage:
$0 [opts] [filename]
  -f FS      set field separator
  -R         suppress revision number
  -s         suppress success status
  -v         output verbose messages
  -h         show this help message
  -B BRANCH  show BRANCH only
  -d         debug mode
EOF
    exit 1
}

function unpack
{
    suffix=${1/*./} 
    case $suffix in
	"gz")
	    zcat $1
	    ;;
	"bz2")
	    bzcat $1
	    ;;
	"lzma")
	    lzcat $1
	    ;;
	"xz")
	    xzcat $1
	    ;;
	*)
	    cat $1
	    ;;
    esac
}

function check_log
{
    if [ ! -f $1 ]; then
	echo "ERR_UNKNOWN"
	return
    fi

    unpack $1 | tail -n 1 | grep "^Success :" > /dev/null 
    if [ 0 -eq $? ]; then
	echo "SUCCESS"
    else
        unpack $1 | awk '
BEGIN {
stage="ERR_DOWNLOAD"
}

$0=="prepare buildreqs"   { stage="ERR_BUILDDEP" }
$0=="prepare sources"     { stage="ERR_DOWNLOAD" }
$0~/^compare sha256sum of .* NO/ { stage="ERR_CHECKSUM" }
$0=="error: Failed build dependencies:" { stage="ERR_BUILDDEP" }
$1=="Executing(%prep):"   { stage="ERR_RPM_INSTALL" }
$1=="Executing(%build):"  { stage="ERR_RPM_BUILD"   }
$1=="Executing(%check):"  { stage="ERR_RPM_CHECK"   }
$1=="Executing(%clean):"  { stage="ERR_RPM_CLEAN"   }
stage=="ERR_RPM_CLEAN" && $1=="Success" && $2==":"  { stage="SUCCESS" }
END {
    printf "%s\n", stage
}
'
    fi
}

while getopts "f:B:hRsvd" opt; do
    case $opt in
	R)
	    WITHOUT_REVISION="1"
	    ;;
	s)
	    WITHOUT_SUCCESS="1"
	    ;;
	v)
	    progress=0
	    ;;
	f)
	    SEP=$OPTARG
	    ;;
	B)
	    BRANCH=$OPTARG
	    ;;
	d)
	    DEBUG=1
	    ;;
	h) 
	    usage
	    ;;
    esac
done
shift $(($OPTIND - 1))

REPORT_LOG=$1


REPO=""
case "$BRANCH" in
    trunk)
	REPO="trunk/pkgs"
	;;
    stable_4)
	REPO="branches/STABLE_4/pkgs"
	;;
    stable_5)
	REPO="branches/STABLE_5/pkgs"
	;;
    stable_6)
	REPO="branches/STABLE_6/pkgs"
	;;
    stable_7)
	REPO="branches/STABLE_7/pkgs"
	;;
    stable_8)
	REPO="branches/STABLE_8/pkgs"
	;;
    *)
	error "-B $BRANCH is not supported"
	;;
esac

# this script requires some external commands
type bc > /dev/null 2>&1 || error " error, please install  \"bc\" command "
type find > /dev/null 2>&1 || error " error, please install \"find\" command "
type awk > /dev/null 2>&1 || error " error, please install \"awk\" command "
type svn > /dev/null 2>&1 || error " error, please install \"svn\" command "
# echo, date

# load the last timestamp
TSTAMP=0
if [ -n "$REPORT_LOG" -a -f "$REPORT_LOG" ]; then
    TSTAMP=`tail -n 1 "$REPORT_LOG"`
    [ "$TSTAMP" -gt 0 ] > /dev/null 2>&1 || error "format error in $REPORT_LOG"
fi

# generates option string for find
opt=""
if [ "$TSTAMP" -gt 0 ]; then
    NOW=`date +%s`
    # !!FIXME!!
    ARG=`echo "($NOW - $TSTAMP + 59) / 60 " | \bc`
    opt="-mmin -$ARG"
fi

if [ $progress -ge 0 ]; then
    echo -n "." > /dev/stderr
fi

# parse each build logs
\find -mindepth 2 -maxdepth 2 -name "OmoiKondara.log" $opt | while read log; do
    dir=`dirname $log`
    dir=${dir/.\//}
    spec=$dir/$dir.spec

    if [ $progress -ge 0 ]; then
	progress=$(($progress + 1))
	if [ $progress -ge 50 ]; then
	    echo -n "." > /dev/stderr
	    progress=0
	fi
    fi

    # skip not build yet
    [ -f $dir/OBSOLETE ] && continue
    [ -f $dir/SKIP ] && continue
    [ -f $dir/.SKIP ] && continue

    [ -f $spec ] || continue

    # skip when $dir/$dir.spec is newer than $log
    t1=`stat --format "%Y" "$spec"` || error "stat $spec faile"
    t2=`stat --format "%Y" "$log"` || error "stat $log faile"
    [ $t1 -ge $t2 ] && continue

    code=`check_log  "$log"` || error "check_log $log failed"

    [ -n "$WITHOUT_SUCCESS" -a "SUCCESS" == $code ] && continue

    # check branch if required
    if [ -n "$REPO" ]; then
	svn info $spec 2>/dev/null | grep "^URL: .*$REPO/$spec$" > /dev/null
	if [ $? -eq 1 ]; then
	    debug "$dir is not a visioned pkg in $REPO, skip"
	    continue
	fi
    fi
    # skip if $spec is changed 
    svn st $dir 2>/dev/null | grep '^M' > /dev/null
    if [ $? -eq 0 ]; then
	debug "$dir is modified, skip"
	continue
    fi

    if [ -z "$WITHOUT_REVISION" ]; then
        # retrive svn revision
	rev=`svn info $spec |awk '$0~/^Last Changed Rev: / {print $4}'` || error "svn failed."
	[ -z "$rev" ] && continue

	echo "$dir$SEP$rev$SEP$code"
    else
	echo "$dir$SEP$code"
    fi
done


exit 0
