#!/bin/sh
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

LANG=C

function error 
{
    echo $@ > /dev/stderr
    exit 3
}

if [ $# -ne 3 ]; then
    cat <<EOF > /dev/stderr
usage:
    $0   srcfile  lineno text
EOF
    exit 4
fi

src=$1
lineno=$2
text=$3

[ -f $src ] || error "no such file, $src"

# make backup if required
[ -f $src.$suffix ] || cp $src $src.$suffix

tmp=$src.backup.$$
cp $src $tmp || error "failed to cp src as tmp"


cat $tmp | awk -vLINENO="$lineno" -vTEXT="$text" '
BEGIN{ 
    while (getline>0) {
	if (NR==LINENO) {
	    print TEXT 
	}
	print $0
    }
}' > $src

exit 0
