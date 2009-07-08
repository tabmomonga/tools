#!/bin/bash

export PATH=$PATH:/usr/sbin:/sbin
export LANG=C
DIA='dialog --backtitle Momonga --title'
PID=$$
INST_ROOT="/install"

source `dirname $0`/libmomo-install
source `dirname $0`/libmomo-messages

if [ ! $UID = 0 ] ; then
    echo "$0: You need to be root to perform this script."
    exit 1
fi

if [ ! -d /boot_kern ]; then
    echo "$0: /boot_kern is not exists. installation aborted."
    exit 1
fi

# welcome message
$DIA "Welcome to Momonga livecd installer" \
  --msgbox "$WELCOME" 16 60
if [ $? = 1 ]; then
    echo "$0: aborded"
    exit 1
fi

# check mount
cat /proc/mounts |awk '{ print $2 }'|grep "^${INST_ROOT}$" > /dev/null
if [ $? = 1 ]; then
    $DIA "Target Partition not mounted" \
      --msgbox "$NOT_MOUNTED" 16 60
    exit 1
fi

detect_hdd
select_swap
create_fstab

# fstab confirm
$DIA "/etc/fstab for new system" \
  --yesno "`cat /tmp/$0.fstab.$PID|while read a ; do echo "$a\n";done`-------------\n$FSTAB_CONFIRM" 20 60
if [ $? = 1 ]; then exit 1 ; fi

# format swap partition
$DIA "format swap partition" \
  --yesno "$SWAP_CONFIRM\n\nCommand:\n# mkswap `cat /tmp/$0.swap_selected.$PID`" 16 60
if [ $? = 1 ]; then exit 1 ; fi
mkswap `cat /tmp/$0.swap_selected.$PID` > /dev/null 2>&1

# copy to HDD
$DIA "Copy system files to HDD" \
  --yesno "$COPY_CONFIRM" 16 60
if [ $? = 1 ]; then exit 1 ; fi
for d in proc sys selinux media mnt srv home tmp; do
    echo "Creating $d"
    mkdir -p $INST_ROOT/$d
done
chmod 1777 $INST_ROOT/tmp
for d in bin dev etc lib lib64 opt root sbin usr var ; do
    if [ -d /$d ]; then
	echo "Copying $d"
	cp -a /$d $INST_ROOT/
    fi
done
chmod 700 $INST_ROOT/root

cp -f /tmp/$0.fstab.$PID $INST_ROOT/etc/fstab

echo "Copying kernel"
mkdir -p $INST_ROOT/boot
cp -a /boot_kern/* $INST_ROOT/boot
rm -f $INST_ROOT/boot/initrd-`uname -r`.img
f=`cat /tmp/$0.fstab.$PID|head -1|awk '{ print $3 }'`
cat $INST_ROOT/sbin/mkinitrd |sed 's,TMPDIR="",TMPDIR=/tmp,' > $INST_ROOT/tmp/mkinitrd.tmp
with_fs=`cat /tmp/$0.fstypes.$PID|sort|uniq|while read f ; do echo -n "--with=$f "; done`
chroot $INST_ROOT mount /sys
chroot $INST_ROOT mount /proc
chroot $INST_ROOT bash /tmp/mkinitrd.tmp /boot/initrd-`uname -r`.img `uname -r` $with_fs \
 > /dev/null 2>&1
##debug rm -f $INST_ROOT/tmp/mkinitrd.tmp
chroot $INST_ROOT umount /sys
chroot $INST_ROOT umount /proc


# post install settings
if [ -f shutdown.patch ]; then
    cp -f shutdown.patch $INST_ROOT/tmp/shutdown.patch
    pushd $INST_ROOT > /dev/null
    patch -p0 -R < $INST_ROOT/tmp/shutdown.patch > /dev/null 2>&1
    rm -f $INST_ROOT/tmp/shutdown.patch
    popd > /dev/null
fi

chroot $INST_ROOT /usr/sbin/userdel momonga >/dev/null 2>&1
cat /etc/sudoers | sed '/^momonga/d' > /etc/sudoers.$PID
cp -f /etc/sudoers.$PID /etc/sudoers ; rm -f /etc/sudoers.$PID

echo "Please input Your root Password for new system."
passwd_ok=1
until [ $passwd_ok = 0 ]; do
    chroot $INST_ROOT /usr/bin/passwd root
    passwd_ok=$?
done

cat << EOF > $INST_ROOT/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=localhost
EOF

cat << EOF > $INST_ROOT/etc/hosts
127.0.0.1 localhost.localdomain localhost
EOF

cat << EOF > $INST_ROOT/etc/rc.local
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

touch /var/lock/subsys/local
EOF

chroot $INST_ROOT /usr/sbin/netconfig

echo "Setting default runlevel to 3"
mv $INST_ROOT/etc/inittab $INST_ROOT/etc/inittab.$PID
perl -npe 's/id:5:initdefault:/id:3:initdefault:/' $INST_ROOT/etc/inittab.$PID \
       > $INST_ROOT/etc/inittab
chmod 755 $INST_ROOT/etc/inittab
rm -f $INST_ROOT/etc/inittab.$PID

echo "Setting SELinux Disable"
mv $INST_ROOT/etc/selinux/config $INST_ROOT/etc/selinux/config.$PID
perl -npe 's/SELINUX=permissive/SELINUX=disabled/' $INST_ROOT/etc/selinux/config.$PID \
	> $INST_ROOT/etc/selinux/config
chmod 600 $INST_ROOT/etc/selinux/config
rm -f $INST_ROOT/etc/selinux/config.$PID


# boot configration
if [ `uname -m` == "i686" ] || [ `uname -m` == "x86_64" ]; then
    install_grub
fi
if [ `uname -m` == "ppc" ] || [ `uname -m` == "ppc64" ]; then
    install_yaboot
fi

echo
echo
echo "Install Finished!!"
echo "You may umount /install/* partition before rebooting."

