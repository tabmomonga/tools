#!/bin/bash
#
#  Hiromasa YOSHIMOTO <y@momonga-linux.org>
#

LANG=C

function error 
{
    echo $@ > /dev/stderr
    exit 3
}

if [ $# -ne 5 ]; then
    cat <<EOF > /dev/stderr
usage:
    $0   srcfile  lineno oldstr newstr suffix
EOF
    exit 4
fi

src=$1
lineno=$2
oldstr=$3
newstr=$4
suffix=$5

[ -f $src ] || error "no such file, $src"

# make backup if required
[ -f $src.$suffix ] || cp $src $src.$suffix

chmod u+w $src

sed --in-place -e ${lineno}s,${oldstr},${newstr},g $src

exit 0
