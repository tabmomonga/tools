#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

BIN=`dirname $0`
BIN=`readlink -f $BIN`
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
lastpatch=`cat $spec | awk 'tolower($1)~/^patch[0-9]*/ {tmp=$1} END{print tmp}'`

if [ -z "$lastpatch" ]; then
	lastpatch="buildroot:"
fi

cp $spec $spec.$$
cat $spec.$$ | awk -vLASTPATCH=$lastpatch -vPATCH=$patch '
function abort(msg){
    printf msg
    exit 3
}
BEGIN{ 
    w=match(LASTPATCH,/[1-9][0-9]*/,num)
    if (w!=0){
	pnum=int(num[0])
	pnum+=1
    }else{
	pnum=1
    }


    patch_macro_done=0
    patch_tag_done=0

    while (getline>0) { 
	if ($1~/%build/) {
	    if (0!=patch_macro_done){
		abort("**BUG** file parse error")
	    }	    
	    print "%patch"pnum" -p1 -b .gcc46~\n"
	    patch_macro_done=1
	}
	
	print $0

	if (tolower($1)==tolower(LASTPATCH)) {
	    if (0!=patch_tag_done){
		abort("**BUG** file parse error")
	    }
	    print "Patch"pnum": "PATCH
	    patch_tag_done=1
	}
    }
}
' > $spec



