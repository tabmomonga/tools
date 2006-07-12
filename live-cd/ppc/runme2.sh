#!/bin/bash
#
# run this script to create a LiveCD in /tmp/livecd.iso
# Your kernel image has to be in $ROOT/boot/vmlinuz or $ROOT/vmlinuz
# 

if [ ! $# = 2 ]; then
        echo "$0: [live env root dir] [kernel version] [output iso image]"
        exit 1
fi
export ROOT=$1
export KERNEL=$2
#ISOFILE=$3


export PATH=.:./tools:../tools:/usr/sbin:/usr/bin:/sbin:/bin:/

CHANGEDIR="`dirname \`readlink -f $0\``"
echo "Changing current directory to $CHANGEDIR"
cd $CHANGEDIR

. liblinuxlive || exit 1
. config || exit 1

./install $ROOT

VMLINUZ=$ROOT/boot/vmlinuz-$KERNEL
#VMLINUZ=$ROOT/boot/vmlinuz-2.6.15-5m
#VMLINUZ=$ROOT/boot/vmlinuz-2.6.15-0.7.7m
if [ -L "$VMLINUZ" ]; then VMLINUZ=`readlink -f $VMLINUZ`; fi
if [ "`ls $VMLINUZ 2>/dev/null`" = "" ]; then echo "cannot find $VMLINUZ"; exit 1; fi

header "Creating LiveCD from your Linux"

rm -rf $CDDATA
rm -rf /tmp/$ISONAME

mkdir -p $CDDATA/base
mkdir -p $CDDATA/modules
mkdir -p $CDDATA/optional
mkdir -p $CDDATA/rootcopy

echo "copying cd-root to $CDDATA, using kernel from $VMLINUZ"
echo "Using kernel modules from $ROOT/lib/modules/$KERNEL"
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

echo "creating initrd image..."
cd initrd
./initrd_create.3
if [ "$?" -ne 0 ]; then exit; fi
cd ..

cp initrd/$INITRDIMG.gz $CDDATA/boot/initrd.3.gz
rm initrd/$INITRDIMG.gz

echo "creating initrd image..."
cd initrd
./initrd_create.S
if [ "$?" -ne 0 ]; then exit; fi
cd ..

cp initrd/$INITRDIMG.gz $CDDATA/boot/initrd.S.gz
rm initrd/$INITRDIMG.gz

echo "creating compressed images..."

for dir in bin etc home lib opt root usr sbin var; do
    if [ -d $ROOT/$dir ]; then
      echo "base/$dir.mo"
      create_module $ROOT/$dir $CDDATA/base/$dir.mo -keep-as-directory
      if [ $? -ne 0 ]; then exit; fi
    fi
done

echo "creating LiveCD ISO image..."
#cd $CDDATA


CDLABEL=livemomonga

rm -f /tmp/live_data_4591/base/opt.mo

mkhybrid -v -R -D -o /tmp/$ISONAME -part -hfs -T -r -l -J -sysid PPC -A "$CDLABEL" -V "$CDLABEL" -hfs-bless /tmp/live_data_4591/boot -map /tmp/live_data_4591/boot/mapping -magic /tmp/live_data_4591/boot/magic -no-desktop -allow-multidot /tmp/live_data_4591/ 

