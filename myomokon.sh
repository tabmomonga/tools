#!/bin/sh
### $Id$

interactive=no
quiet=no
noexec=no
verbose=no
omoikondara="../tools/OmoiKondara"
omoikondaraopts="-v -r -ba -S"
LANG=C && export LANG
LC_ALL=C && export LC_ALL

while getopts "ino:q" option
do
	case ${option} in 
	i)
  		interactive=yes
  		;;
	n)
		noexec=yes
		;;
	o)
		omoikondaraopts=${OPTARG}
		;;
	q)
		quiet=yes
		;;
  	esac
done
shift $((${OPTIND} - 1))
  
rpmpackages=`rpm -qa --qf '%{NAME}\n'`
buildtargets=`for i in ${rpmpackages}; do test -d ${i} && echo ${i}; done`
targetcount=`echo ${buildtargets} | wc -l | awk '{print $1}'`

if [ ${targetcount} == "0" ]; then
	if [ x${quiet} != "xyes" ]; then
		echo "No Package is found in this directory, exiting now..."
	fi
	exit 1
fi

if [ x${quiet} != "xyes" ]; then
	if [ ${targetcount} == "1" ]; then
		echo "following package will be built:"
	else
		echo "following package(s) will be built:"
	fi
	for i in "${buildtargets}"; do
		echo -n ${i}
	done; echo ""
fi

if [ x${quiet} != "xyes" -a x${interactive} == "xyes" ]; then
	read -p 'Proceed[y/N]?: ' continuep
	if [ x${continuep} != "xY" -a x${continuep} != "xy" ]; then
		echo "Done nothing."
		exit 1
	fi
	echo "Okey, now we start to build all you need..."
fi

if [ x${noexec} != "xyes" ]; then
	${omoikondara} ${omoikondaraopts} ${buildtargets}
else
	true
fi

status=${?}

if [ x${quiet} != "xyes" ]; then
	if [ x${status} != "x0" ]; then
		echo 'Sorry, it seems to be failure.'
		echo 'Please check */OmoiKondara.log.'
	else
		echo 'Building done.'
	fi
fi

exit ${status}
