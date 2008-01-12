#!/bin/sh
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=${BIN:-.}

function error 
{
    echo $@ > /dev/stderr
    exit 2
}

if [ $# -ne 2 ]; then
    cat<<EOF > /dev/stderr
usage:
 $0 patch spec
EOF
    exit 1
fi

patch=$1
spec=$2


cat $spec | grep -i "^patch[0-9]*[ \t]*:[ \t]*$patch" > /dev/null && error "already added"

# search last patch tag
lastpatch=`cat $spec | awk 'tolower($1)~/^patch[0-9]*:$/ {tmp=$1} END{print tmp}'`


cp $spec $spec.$$
cat $spec.$$ | awk -vLASTPATCH=$lastpatch -vPATCH=$patch '
BEGIN{ 
    w=match(LASTPATCH,/[1-9][0-9]*/,num)
    if (w!=0){
	pnum=int(num[0])
	pnum+=1
    }else{
	pnum=1
    }


    while (getline>0) { 
	if ($1~/%build/) {
	    print "%patch"pnum" -p1 -b .gcc43~\n"
	}
	
	print $0

	if ($1==LASTPATCH) {
	    print "Patch"pnum": "PATCH
	}
    }
}
' > $spec



