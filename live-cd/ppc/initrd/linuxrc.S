#!/bin/ash

export PATH=.:/:/usr/sbin:/usr/bin:/sbin:/bin
. liblinuxlive

header "starting Linux Live scripts <http://www.linux-live.org/>"

echolog "mounting /proc and /sys filesystems"
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# setup DEBUGCMD variable. If debug boot option is present, call debug()
# function several times during script's execution
if [ "`cmdline_parameter debug`" ]; then DEBUGCMD="debug"; else DEBUGCMD=""; fi

$DEBUGCMD

# I have to set these variables very carefully
UNION=/union
MEMORY=/memory
MOUNTDIR=mnt
CHANGES=$MEMORY/changes
COPY2RAM=$MEMORY/copy2ram
IMAGES=$MEMORY/images
INITRAMDISK=$MOUNTDIR/live

# we need cdrom support, isofs support, unionfs support, etc
busybox mkdir -p $MEMORY

modprobe_essential_modules
setup_dma

$DEBUGCMD

# $UNION will be used as a root directory, livecd modules will be added soon.
echolog "setup union on $UNION"
busybox mkdir -p $UNION

CHANGESDEV="`cmdline_value changes`"
if [ "$CHANGESDEV" != "" ]; then
   busybox echo "mounting $CHANGESDEV to $MEMORY"
   mount_device $CHANGESDEV $MEMORY
else false; fi

# mount tmpfs only in the case when changes= boot parameter was empty
# or we were not able to mount the storage device
if [ $? -ne 0 ]; then busybox mount -t tmpfs -o "size=80%" tmpfs $MEMORY; fi

busybox mkdir -p $CHANGES
busybox mkdir -p $COPY2RAM
busybox mkdir -p $IMAGES
busybox mount -t unionfs -o dirs=$CHANGES=rw unionfs $UNION
if [ $? -ne 0 ]; then fatal "can't setup union in /union directory"; fi

$DEBUGCMD

# try to find livecd data directory. If not found, try modprobing
# USB kernel modules and repeat the find procedure again
echolog "looking for data modules"
DATA="`find_live_data_dir $MOUNTDIR`";
if [ "$DATA" = "" ]; then modprobe_usb_modules; DATA="`find_live_data_dir $MOUNTDIR`"; fi
if [ "$DATA" = "" ]; then fatal "Data for LiveCD not found. Are you using SCSI?"; fi
echolog "found in $DATA"

$DEBUGCMD

# If toram or copy2ram boot parameter is present, copy all .mo modules to RAM.
# (skip modules from /optional/ which are not listed in load= boot option)
# Finaly modify DATA variable so it will point to correct directory
if [ "`cmdline_parameter toram`" != "" -o "`cmdline_parameter copy2ram`" != "" ]; then
   echolog "copying modules to RAM, this may take some time"
   copy_to_ram $DATA $COPY2RAM
   cd_autoeject 1
   busybox umount $DATA 2>/dev/null
   if [ $? -ne 0 ]; then busybox umount `busybox dirname $DATA` 2>/dev/null; fi
   DATA=$COPY2RAM
   cd_autoeject 0
fi

busybox mkdir -p $UNION/boot
busybox mount -o bind $DATA $UNION/boot

$DEBUGCMD

# DATA contains path to the base directory of all .mo images which need
# to be mounted and inserted into live filesystem. Do it now.
echolog "inserting all modules and creating live filesystem"
union_insert_modules $UNION $DATA $IMAGES

$DEBUGCMD

busybox echo "copying rootchanges"
copy_rootchanges $DATA $UNION

$DEBUGCMD

busybox echo "creating /etc/fstab"
activate_fstab $UNION

# More likely these directories aren't there.
# Even if they are, this won't hurt.
busybox mkdir -p $UNION/proc
busybox mkdir -p $UNION/sys
busybox mkdir -p $UNION/tmp
busybox mkdir -p $UNION/dev

$DEBUGCMD

# Union contains all the files and directories unioned from all modules.
# Change root directory to it, and move initrd's root to /mnt/live/initramdisk
# Finaly execute /sbin/init to start the distribution.
echolog "changing root directory..."
cd $UNION
busybox mkdir -p $INITRAMDISK

busybox umount /sys # we won't need it anymore
if [ ! -e $UNION/dev/console ]; then busybox mknod $UNION/dev/console c 5 1; fi

if [ -x $UNION/usr/sbin/chroot ];
  then CHROOT=/usr/sbin/chroot
  else CHROOT=/usr/bin/chroot
fi

header "linux live end"
busybox pivot_root . $INITRAMDISK
exec $CHROOT . sbin/init S <dev/console >dev/console 2>&1; fi

header "ERROR!"
echolog "You are not supposed to be here, something went wrong!"
echolog "Even Ctrl+Alt+Del won't help you in kernel panic."

