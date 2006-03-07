#!/bin/sh

PKGLISTS_BASE=pkglists/pkglist.base
PKGLISTS_XORG=pkglists/pkglist.xorg
PKGLISTS_XFCE4=pkglists/pkglist.xfce4
PKGLISTS_GNOME=pkglists/pkglist.gnome
PKGLISTS_KDE=pkglists/pkglist.kde
PKGLISTS_OOO=pkglists/pkglist.ooo
PKGLISTS_ADD=pkglists/pkglist.add
REPOBASE=$1

INSTALL_XORG=yes
INSTALL_XFCE4=no
INSTALL_GNOME=yes
INSTALL_KDE=no
INSTALL_OOO=yes

XORG_LANG=ja_JP.EUC-JP
XORG_SESSION=gnome
XORG_XIM=SCIM


if [ ! $# = 1 ] ; then
	echo "$0: [Repository Base Directory]"
	exit 1
fi

if [ ! -d $REPOBASE ]; then
	echo "Repository Base Directory: $REPOBASE not found"
	exit 1
fi

if [ ! -f $PKGLISTS_BASE ]; then
	echo "$PKGLISTS_BASE: file not found"
	exit 1
fi

echo "Making directories"
mkdir -p $REPOBASE/dev $REPOBASE/etc

echo "Making /dev/null"
mknod $REPOBASE/dev/null c 1 3

echo "Creating /etc/fstab"
cat << EOF > $REPOBASE/etc/fstab
none     /dev/pts       devpts          gid=5,mode=620  0 0
none    /proc           proc            defaults        0 0
EOF

echo "Creating /etc/hosts"
cat << EOF > $REPOBASE/etc/hosts
127.0.0.1       localhost.localdomain   localhost livecd
EOF

touch $REPOBASE/etc/resolv.conf

echo "Copying yum setting"
cp -a /etc/yum.repos.d $REPOBASE/etc/yum.repos.d.tmp
perl -npe 's/exclude.*\n//' /etc/yum.conf > $REPOBASE/etc/yum.conf.tmp
echo 'reposdir=/etc/yum.repos.d.tmp' >> $REPOBASE/etc/yum.conf.tmp

echo "Installing base package"
yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_BASE`

if [ x$INSTALL_XORG = "xyes" -a -f $PKGLISTS_XORG ]; then
	echo "Installing Xorg package"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_XORG`
fi

if [ x$INSTALL_XFCE4 = "xyes" -a -f $PKGLISTS_XFCE4 ]; then
	echo "Installing XFce4 package"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_XFCE4`
fi

if [ x$INSTALL_GNOME = "xyes" -a -f $PKGLISTS_GNOME ]; then
	echo "Installing GNOME package"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_GNOME`
fi

if [ x$INSTALL_KDE = "xyes" -a -f $PKGLISTS_KDE ]; then
	echo "Installing KDE package"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_KDE`
fi

if [ x$INSTALL_OOO = "xyes" -a -f $PKGLISTS_OOO ]; then
	echo "Installing OpenOffice.org package"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_OOO`
fi

if [ -f $PKGLISTS_ADD ]; then
	echo "Installing additional packages"
	yum -c $REPOBASE/etc/yum.conf.tmp -y --installroot=$REPOBASE install \
	`cat $PKGLISTS_ADD`
fi


echo "Creating Network settings"
cat << EOF > $REPOBASE/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=livecd
EOF
cat << EOF > $REPOBASE/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
EOF


if [ x$INSTALL_XORG = "xyes" -a -f $PKGLISTS_XORG ]; then
echo "Creating Xorg configs"
cat << EOF > $REPOBASE/etc/sysconfig/xinit-lang
$XORG_LANG
EOF
cat << EOF > $REPOBASE/etc/sysconfig/xinit-session
$XORG_SESSION
EOF
cat << EOF > $REPOBASE/etc/sysconfig/xinit-xim
$XORG_XIM
EOF
fi

echo "Creating System Font setting"
echo 'SYSFONT="latarcyrheb-sun16"' >> $REPOBASE/etc/sysconfig/i18n

echo "Creating /etc/localtime"
cp $REPOBASE/usr/share/zoneinfo/Japan $REPOBASE/etc/localtime


echo "Modifying /etc/init.d/halt, /etc/init.d/netfs"
cp shutdown.patch $REPOBASE/tmp
(
	cd $REPOBASE
	patch -p1 < $REPOBASE/tmp/shutdown.patch
)


if [ x$INSTALL_XORG = "xyes" -a -f $PKGLISTS_XORG ]; then
	echo "Setting default runlevel to 5"
	mv $REPOBASE/etc/inittab $REPOBASE/etc/inittab.rpmorig
	perl -npe 's/id:3:initdefault:/id:5:initdefault:/' $REPOBASE/etc/inittab.rpmorig \
		> $REPOBASE/etc/inittab
	chmod 755 $REPOBASE/etc/inittab
fi

echo "Adding to /etc/rc.local"
cat << EOF >> $REPOBASE/etc/rc.local
if [ \`/sbin/runlevel | awk '{ print \$2 }'\` == "5" ]; then
        LANG=ja_JP.EUC-JP /usr/bin/system-config-display
fi
/usr/bin/system-config-keyboard --text
EOF


echo "Create account and setting password"
echo momonga | chroot $REPOBASE passwd --stdin root
chroot $REPOBASE /usr/sbin/useradd momonga
echo momonga | chroot $REPOBASE passwd --stdin momonga
echo 'momonga ALL=(ALL) NOPASSWD: ALL' >> $REPOBASE/etc/sudoers


echo "Copying installer staff"
cp -a inst_dir $REPOBASE/inst_dir
find $REPOBASE/inst_dir -name ".svn" -exec rm -rf {} \; 2> /dev/null


echo "Cleaning up"
umount $REPOBASE/proc
rm -fv $REPOBASE/etc/yum.conf.tmp
rm -rf $REPOBASE/etc/yum.repos.d.tmp
find $REPOBASE -name "*.rpmorig" -exec rm -fv {} \;


echo "Done!"

