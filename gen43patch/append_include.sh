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
    $0   srcfile   header suffix
EOF
    exit 4
fi

src=$1
header=$2
suffix=$3

[ -f $src ] || error "no such file, $src"

# skip if 'src' is already including 'header'
grep "^#include.*$header" $src > /dev/null && error "$src seems to be  already including $header"

# make backup if required
[ -f $src.$suffix ] || cp $src $src.$suffix


tmp=$src.backup.$$
cp $src $tmp || error "failed to cp src as tmp"

chmod u+w $src

cat $tmp | awk -vHEADER="$header" '
     BEGIN{
	 found=0
	 while (getline>0){
	     if (found==0 && ($1=="#include" || $1~/^#if.*/) ) {
		 printf("#include <%s>\n",HEADER)
                 found=1
	     }
	     print $0
	 }
     }
' > $src

# rm $tmp

exit 0
