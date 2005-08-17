#!/bin/bash

MOUNT="`mount | grep -e hd | cut -f 1 -d " "`"
test -n "$MOUNT"
if [ $? -eq 0 ];
   then for i in $MOUNT
   	do
	  umount $i
	done
   else echo "no umount";
fi
halt -nf
