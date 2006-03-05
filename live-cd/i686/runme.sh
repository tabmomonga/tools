#!/bin/bash
#
# run this script to create a LiveCD in /tmp/livecd.iso
# Your kernel image has to be in $ROOT/boot/vmlinuz or $ROOT/vmlinuz
# 

if [ ! $# = 3 ]; then
	echo "$0: [live env root dir] [kernel version] [output iso image]"
	exit 1
fi

export ROOT=$1
export KERNEL=$2
ISOFILE=$3

echo "cleanup yum cache"
rm -rf $ROOT/var/cache/yum/*

export PATH=.:./tools:../tools:/usr/sbin:/usr/bin:/sbin:/bin:/

CHANGEDIR="`dirname \`readlink -f $0\``"
echo "Changing current directory to $CHANGEDIR"
cd $CHANGEDIR

. liblinuxlive || exit 1
. config || exit 1

./install $ROOT

VMLINUZ=$ROOT/boot/vmlinuz-$KERNEL
if [ -L "$VMLINUZ" ]; then VMLINUZ=`readlink -f $VMLINUZ`; fi
if [ "`ls $VMLINUZ 2>/dev/null`" = "" ]; then echo "cannot find $VMLINUZ"; exit 1; fi

header "Creating LiveCD from your Linux"

mkdir -p $CDDATA/base
mkdir -p $CDDATA/modules
mkdir -p $CDDATA/optional
mkdir -p $CDDATA/rootcopy

echo "copying cd-root to $CDDATA, using kernel from $VMLINUZ"
echo "Using kernel modules from /lib/modules/$KERNEL"
cp -R cd-root/* $CDDATA
cp -R tools $CDDATA
cp -R info/* $CDDATA
cp $VMLINUZ $CDDATA/boot/vmlinuz

echo "creating initrd image..."
cd initrd
./initrd_create
if [ "$?" -ne 0 ]; then exit; fi
cd ..

cp initrd/$INITRDIMG.gz $CDDATA/boot/initrd.gz
rm initrd/$INITRDIMG.gz

echo "creating compressed images..."

for dir in bin etc home lib opt root usr sbin var; do
    if [ -d $ROOT/$dir ]; then
      echo "base/$dir.mo"
      create_module $ROOT/$dir $CDDATA/base/$dir.mo -keep-as-directory
      if [ $? -ne 0 ]; then exit; fi
    fi
done

# for install
if [ -d $ROOT/boot ]; then
    echo "base/boot_kern.mo"
    mv $ROOT/boot $ROOT/boot_kern
    create_module $ROOT/boot_kern $CDDATA/base/boot_kern.mo -keep-as-directory
    if [ $? -ne 0 ]; then mv $ROOT/boot_kern $ROOT/boot ; exit; fi
    mv $ROOT/boot_kern $ROOT/boot
fi
echo "base/inst_dir.mo"
create_module $ROOT/inst_dir $CDDATA/base/inst_dir.mo -keep-as-directory
if [ $? -ne 0 ]; then exit; fi

echo "creating LiveCD ISO image..."
cd $CDDATA
./make_iso.sh $ISOFILE

cd /tmp
header "Your ISO is created in $ISOFILE"

