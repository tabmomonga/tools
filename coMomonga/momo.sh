#!/bin/bash

# 
ROOTDIR="/tmp"
TMPDIR="$ROOTDIR/tmp"
BASEDIR=`pwd`
VMLINUX_MODULE="$BASEDIR/vmlinux-modules.tar.gz"
# TARGETDISK="/home/meke/momoco/momo-dev.img"
TARGETDISK="/dev/cobd2"
TARGETDIR="/mnt/target"

# 
#SERVER="ftp://dist.momonga-linux.org/pub/momonga/development/PKGS/"
SERVER="http://dist.momonga-linux.org/pub/momonga/2/PKGS"

# Wget
# export http_proxy="xxx.xxx.xxx.xxx:8080"
# export ftp_proxy="xxx.xxx.xxx.xxx:8080"

# temp dir
CACHEDIR="$TMPDIR/cache"
MINIROOT="$TMPDIR/miniroot"


# 
MINIROOT_PKG="beecrypt bzip2 elfutils elfutils-libelf popt rpm"

# release
INSTALL_PKG="Canna Canna-library GConf MAKEDEV MySQL-shared-libs NetworkManager ORBit ORBit2 SDL SysVinit a2ps acl acpid alsa-lib alsa-utils anaconda anaconda-help anaconda-runtime anacron anthy apmd arts-artsc ash aspell aspell-en at atk attr audiofile authconfig authconfig-gtk autoconf autoconf213 autofs automake automake14 automake14-1.4p6 automake15 automake16 automake17 basesystem bash bc beecrypt bind-utils binutils bison bison-1.875c bluez-bluefw bluez-hcidump bluez-libs bluez-pin bluez-utils bogl bogl-bterm bogofilter boost boost-devel booty bridge-utils busybox-anaconda byacc bzip2 bzip2-devel cdecl cdparanoia chasen chkconfig chkfontpath-momonga comps-extras coreutils cpio cpp cracklib cracklib-dicts createrepo crontabs cscope ctags cups-libs curl curl-devel cvs cyrus-sasl cyrus-sasl-devel db4 db4-devel db4-utils dbh dbskkd-cdb dbus dbus-devel dbus-glib dbus-python desktop-file-utils dev86 device-mapper dhclient dialog diffstat diffutils dmapi docbook-dtds docbook-mathml-module docbook-style-dsssl docbook-style-xsl docbook-utils docbook-utils-pdf dosfstools doxygen dump e2fsprogs e2fsprogs-devel eel ed efont-unicode-bdf eject elfutils elfutils-libelf emacs esound ethtool expat expat-devel fam file filesystem findutils finger firefox firstboot flex fontconfig fontconfig-devel fortune-mod freecdb freetype2 ftp gail gaim gawk gc gcc gcc-c++ gcc3.2 gcc3.2-c++ gdb gdbm gdbm-devel gdk-pixbuf gdm gedit gettext ghostscript-resource glib glib-devel glib1 glibc glibc-common glibc-devel glibc-headers glibc-kernheaders glut gmp gmp-devel gnome-keyring gnome-libs gnome-python gnome-python-bonobo gnome-python-canvas gnome-terminal gnome-vfs gnomemeeting gnupg gnutls gpgme gpm gpm-devel grep gsl groff gtksourceview gtk+ gtk+-common gtk+1 gtk-xfce-engine guile gzip hal hdparm hesiod hesiod-devel hotplug htmlview httpd httpd-apr hwdata imlib indent indexhtml info initscripts intltool ipadic iproute iptables iputils irda-utils jadetex japanese-fonts java-common jed jed-common jfsutils jwhois kbd kernel-co kernel-headers kernel-utils kinput2 kpathsea krb5-devel krb5-libs krb5-workstation kudzu kudzu-devel kudzu-python lcms less lftp lha libIDL libaal libacl libacl-devel libao libart_lgpl libavc1394 libbonobo libbonoboui libcap libcap-devel libcroco libdv libf2c libgcc libgcj libgcj-devel libgcrypt libglade libgnome libgnomecanvas libgnomecups libgnomeprint libgnomeprintui libgnomeui libgpg-error libgsf libidn libjconv libjpeg libmad libmng libobjc libogg libogg-devel libpng libraw1394 librsvg libselinux libselinux-devel libsepol libspt libstdc++ libstdc++-devel libstdc++3.2 libstdc++3.2-devel libtermcap libtermcap-devel libtiff libtool libtool-libs libungif libusb libusb-devel libuser libuser-devel libvorbis libvorbis-devel libwnn6 libwvstreams libxfce4mcs libxfce4util libxfcegui4 libxml2 libxml2-devel libxml2-python libxslt linc lockdev lockdev-devel logrotate losetup lsof ltrace lv lvm2 m4 mailcap make man man-pages mathml-dtds mdadm memprof memtest86 metacity mgetty mingetty mkbootdisk mkinitrd mktemp mm module-init-tools momonga-backgrounds momonga-desktop momonga-images momonga-logos momonga-release momonga-rpmmacros mount mozilla mozilla-psm mph mt-st mtools mtr nc ncurses ncurses-devel neon net-tools netconfig newt newt-devel newt-python nfs-utils nscd nss_ldap ntp ntsysv open openh323 openh323gk openjade openldap openldap-devel openslp openssh openssh-clients openssh-server openssl openssl-devel pam pam-devel pango parted passwd patch patchutils pciutils pciutils-devel pcmcia-cs pcre pdksh perl perl-Convert-BinHex perl-DBI perl-Filter perl-IO-stringy perl-MailTools perl-MIME-tools perl-Net-Daemon perl-PlRPC perl-SGMLSpm perl-Tk perl-XML-Dumper perl-XML-Encoding perl-XML-Grove-0.46alpha perl-XML-Parser perl-XML-Twig perl-XML-XPath perl-libxml-perl php pkgconfig prime-dict policycoreutils popt portmap postfix postgresql-libs ppp prelink prime procps psacct psmisc psutils pth pwdb pwlib pygtk pygtk-libglade pyorbit pyparted python python-devel python-sqlite python-urlgrabber pyxf86config qdbm qt quota rcs rdate rdist readline readline-devel redhat-artwork reiser4progs reiserfsprogs rhpl rmt rootfiles rp-pppoe rpm rpm-build rpm-devel rpm-python rsh rsync ruby ruby-newt ruby-progressbar ruby-rpm ruby-sary rxvt samba-client samba-common sary scim scim-anthy scim-canna scim-prime scim-skk screen scrollkeeper sed selinux-policy-targeted setserial setup setuptool sgml-common shadow-utils shared-mime-info skk-jisyo slang slang-devel slocate sox speex sqlite startup-notification strace stunnel subversion sudo suikyo suikyo-ruby swig sylpheed sysfsutils sysklogd syslinux system-config-date system-config-display system-config-keyboard system-config-mouse system-config-network system-config-network-tui system-config-packages system-config-rootpassword system-config-securitylevel system-config-securitylevel-tui system-config-soundcard system-config-users t1lib talk tar tcl tcp_wrappers tcpdump tcsh telnet termcap tetex tetex-doc tetex-dvipsk tetex-latex tetex-vf texinfo thunderbird time tk tmpwatch traceroute truetype-fonts-arabic truetype-fonts-bengali truetype-fonts-ja truetype-fonts-ko truetype-fonts-zh_CN truetype-fonts-zh_TW ttmkfdir tzdata udev uim umb-scheme unzip urw-fonts usbutils usermode usolame utempter util-linux valgrind vim-X11 vim-common vim-enhanced vim-macros vim-minimal vixie-cron vnc-server vte w3m wget which wireless-tools words wvdial xchat xfcalendar xfce-mcs-manager xfce-mcs-plugins xfce-utils xfce4 xfce4-appfinder xfce4-artwork xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-datetime-plugin xfce4-diskperf-plugin xfce4-fsguard-plugin xfce4-icon-theme xfce4-iconbox xfce4-minicmd-plugin xfce4-mixer xfce4-netload-plugin xfce4-notes-plugin xfce4-panel xfce4-session xfce4-session-engines xfce4-showdesktop-plugin xfce4-systemload-plugin xfce4-systray xfce4-taskbar-plugin xfce4-toys xfce4-trigger-launcher xfce4-wavelan-plugin xfce4-weather-plugin xfce4-windowlist-plugin xfce4-xkb-plugin xfce4-xmms-plugin xfdesktop xffm xfprint xfsdump xfsprogs xfwm4 xfwm4-themes xinetd xinitrc xloadimage xml-common xmlrpc-epi xmms xorg-x11 xorg-x11-100dpi-fonts xorg-x11-75dpi-fonts xorg-x11-ISO8859-15-75dpi-fonts xorg-x11-ISO8859-2-75dpi-fonts xorg-x11-ISO8859-9-75dpi-fonts xorg-x11-Mesa-libGL xorg-x11-Mesa-libGLU xorg-x11-base-fonts xorg-x11-deprecated-libs xorg-x11-devel xorg-x11-font-utils xorg-x11-libs xorg-x11-tools xorg-x11-xauth xorg-x11-xdm xorg-x11-xfs xsri xscreensaver yp-tools ypbind yum zip zlib zlib zlib-devel"

#Wget
WGET="wget -nc -nd -P $CACHEDIR "

# rpm
RPM="$MINIROOT/bin/rpm"
export LD_LIBRARY_PATH="$MINIROOT/usr/lib"


umount $TARGETDIR
# 
mkdir -p  $TMPDIR
cd $TMPDIR

# RPM

$WGET $SERVER/i686.mph
$WGET $SERVER/noarch.mph

ruby $BASEDIR/read-mph.rb """$MINIROOT_PKG""" $CACHEDIR "$WGET $SERVER/#{arch}/#{rpm}"  | sh

mkdir -p $MINIROOT
cd $MINIROOT

# rpm
ruby $BASEDIR/read-mph.rb """$MINIROOT_PKG""" $CACHEDIR "rpm2cpio $CACHEDIR/#{rpm} | cpio -id" | sh

# cat $BASEDIR/orig/miniroot-list | awk '{print "rpm2cpio /tmp/tmp/cache/"$1 "| cpio -id" } ' | sh

cd $TMPDIR


mkdir /mnt/target
mkfs.ext3 -j $TARGETDISK

# image file
# mount -o loop -t ext3 $TARGETDISK $TARGETDIR

# block device
mount -t ext3 $TARGETDISK $TARGETDIR

#rpm
mkdir -p $TARGETDIR/var/lib/rpm
$RPM --initdb --root=$TARGETDIR
mkdir -p $TARGETDIR/usr/lib/rpm
mkdir -p $TARGETDIR/dev
mknod $TARGETDIR/dev/null c 1 3
mknod $TARGETDIR/dev/console c 5 1
mknod $TARGETDIR/dev/tty c 5 0

# mknod cobdX
for num in 0 1 2 3 4 5 6 7 8 9
do
	mknod $TARGETDIR/dev/cobd$num b 117 $num
done

# mknod ttyX
for num in 0 1 2 3 4 5 6 7 8 9
do
	mknod $TARGETDIR/dev/tty$num c 4 $num
done


# /etc/fstab
mkdir -p $TARGETDIR/etc
echo "/dev/cobd0      /               ext3    defaults                1 1" > $TARGETDIR/etc/fstab
echo "/dev/cobd1      swap            swap    defaults                0 0" >> $TARGETDIR/etc/fstab
echo "none            /proc           proc    defaults                0 0" >> $TARGETDIR/etc/fstab
echo "none            /dev/pts        devpts  gid=5,mode=620          0 0" >> $TARGETDIR/etc/fstab

mkdir -p $TARGETDIR/etc/X11
cp $BASEDIR/xorg.conf $TARGETDIR/etc/X11/

# CoLinux
tar zxvf $VMLINUX_MODULE -C $TARGETDIR
#mv $TMPDIR/lib/modules/* $TARGETDIR/lib/modules
#chown -R root.root $TARGETDIR/lib/modules

# 
# +

ruby $BASEDIR/read-mph.rb """$INSTALL_PKG""" $CACHEDIR "$WGET $SERVER/#{arch}/#{rpm}" | sh

# rpm
$RPM -ivh --root=$TARGETDIR $CACHEDIR/*.rpm


# /etc/hosts
echo "127.0.0.1	localhost.localdomain localhost" >> $TARGETDIR/etc/hosts
echo "127.0.0.1	coMomonga" >> $TARGETDIR/etc/hosts

#eth
echo "HOSTNAME=coMomonga" > $TARGETDIR/etc/sysconfig/network
echo "NETWORKING=yes" >> $TARGETDIR/etc/sysconfig/network
# echo "NOZEROCONF=yes" >> $TARGETDIR/etc/sysconfig/network
# echo "DEVICE=eth0" > $TARGETDIR/etc/sysconfig/network-scripts/ifcfg-eth0
# echo "ONBOOT=yes" >> $TARGETDIR/etc/sysconfig/network-scripts/ifcfg-eth0


# slocateDB
# /usr/sbin/chroot $TARGETDIR /etc/cron.daily/slocate.cron

# disable auto firstboot
/usr/sbin/chroot $TARGETDIR chkconfig firstboot off
/usr/sbin/chroot $TARGETDIR chkconfig smartd off
/usr/sbin/chroot $TARGETDIR chkconfig cpuspeed off
/usr/sbin/chroot $TARGETDIR chkconfig irqbalance off
/usr/sbin/chroot $TARGETDIR chkconfig lm_sensors off
/usr/sbin/chroot $TARGETDIR chkconfig kudzu off
/usr/sbin/chroot $TARGETDIR chkconfig pcmcia off
/usr/sbin/chroot $TARGETDIR chkconfig postfix off
/usr/sbin/chroot $TARGETDIR chkconfig autofs off
/usr/sbin/chroot $TARGETDIR chkconfig mdmonitor off
/usr/sbin/chroot $TARGETDIR chkconfig xfs off

touch $TARGETDIR/.unconfigured
touch $TARGETDIR/etc/modprobe.conf
touch $TARGETDIR/etc/modules.conf

# patch 

# default runlevel = 5
pushd $TARGETDIR/etc/
patch -p1 < $BASEDIR/inittab-colinux.patch
popd

# gdm config
pushd $TARGETDIR/etc/X11/gdm
patch -p1 < $BASEDIR/gdm.conf-colinux.patch
popd

# xscreensaver config
pushd $TARGETDIR/usr/lib/X11/app-defaults/
patch -p1 < $BASEDIR/xscreensaver-no_stderr.patch
popd

# xfs config(enable tcp listen)
pushd $TARGETDIR/etc/X11/fs
patch -p1 < $BASEDIR/xfs-tcp_listen.patch
popd

# add Default Setting
cat $BASEDIR/authconfig.conf >> $TARGETDIR/etc/sysconfig/authconfig
cat $BASEDIR/keyboard.conf >> $TARGETDIR/etc/sysconfig/keyboard
cat $BASEDIR/clock.conf >> $TARGETDIR/etc/sysconfig/clock

sync
sync

# muriyari umount
umount -fl $TARGETDIR

