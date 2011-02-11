#!/bin/bash
# by Hiromasa YOSHIMOTO

BIN=`dirname $0`
BIN=`readlink -f $BIN`
BIN=${BIN:-.}

function error 
{
    echo $@ > /dev/stderr
    exit 2
}

source $BIN/config ||  error "failed to load $BIN/config "

LANG=C

if [ $# -eq 0 ]; then
	cat<<EOF > /dev/stderr
usage:
	$0  package [...]
EOF
	exit 1
fi

function fetch_required_flags
{
    spec=$1
    log=$2

    LIST=""
    cat $log | grep -e " error: .* \[.*\]" |  sed -e 's|^.*\[\(.*\)\].*$|\1|g' | sort | uniq | while read x; do
	echo -n " $x" | sed -e 's|-Werror=|-Wno-|g'
    done
}

function gen_modifier
{
    spec=$1
    list=$2
    version=`$BIN/dumpversion.rb $spec`

    cat<<EOF
case "\`gcc -dumpversion\`" in
4.6.*)
	# $spec-$version requires this
	CFLAGS="\$RPM_OPT_FLAGS $list"
	CXXFLAGS="\$RPM_OPT_FLAGS $list"
	;;
esac
export CFLAGS CXXFLAGS
EOF
}

function replace_modifier
{
    cat $1 | awk -vMODIFIER="$2" 'BEGIN{
	while (getline > 0) {
	    print $0
            if ($0~/^%build/) 
                 break;
	}
        print MODIFIER
	while (getline > 0) {
	    print $0
	}
}'
}

function process
{
    spec=$1
    log=$2

    list=`fetch_required_flags $spec $log`

    [ -n "$list" ] || return

    oldspec=$spec.fixoptflags~
    cp -f $spec $oldspec

    modifier=`gen_modifier $spec "$list"`
    
    replace_modifier $oldspec "$modifier" > $spec


    $BIN/../increse-rel.rb \
    --address "$ADDRESS" \
    --name    "$NAME" \
    --message "fix CFLAGS and CXXFLAGS for gcc 4.6" $spec
}

while [ -n "$1" ]; do
    if [ -d $1/BUILD -a -f $1/$1.spec -a -f $1/OmoiKondara.log ]; then
	(cd $1; process $1.spec OmoiKondara.log)
    fi
    shift
done
