#!/bin/sh
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

while [ -n "$1" ]; do
	if [ -f $1/$1.spec ]; then
		echo $1
		touch $1/$1.spec
	fi
	shift
done 
