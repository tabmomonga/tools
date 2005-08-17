#!/bin/bash
# ---------------------------------------------------
# Script to create bootable ISO in Linux
# usage: make_iso.sh /tmp/slax.iso
# author: Tomas M. <http://www.linux-live.org>
# ---------------------------------------------------

CDLABEL="momongappctest"

if [ "$1" = "" -o "$1" = "--help" -o "$1" = "-h" ]; then
  echo "This script will create bootable ISO from files in curent directory."
  echo "Current directory must be writable."
  echo "example: $0 /mnt/hda5/slax.iso"
  exit
fi

# isolinux.bin is changed during the ISO creation,
# so we need to restore it from backup.
cp -f boot/isolinux.bi_ boot/isolinux.bin
if [ $? -ne 0 ]; then
   echo "Can't recreate isolinux.bin, make sure your current directory is writable!"
   exit 1
fi

#mkisofs -o "$1" -v -J -R -D -A "$CDLABEL" -V "$CDLABEL" \
#-no-emul-boot -boot-info-table -boot-load-size 4 \
#-b boot/isolinux.bin -c boot/isolinux.boot .

#cdrecord dev=ATAPI:0,1,0 --blank=fast

#mkhybrid -o "$1" -part -hfs -T -r -l -J -sysid PPC \
#-hfs-bless boot/ppc/mac \
#-map boot/mapping \
#-magic boot/magic \
#-no-desktop -allow-multidot 

#mkhybrid -v -R -D -o /tmp/testlive.iso -part -hfs -T -r -l -J \
#-sysid PPC -A "$CDLABEL" -V "$CDLABEL" \
#-hfs-bless /tmp/live_data_2922/boot \
#-map /tmp/live_data_2922/boot/mapping \
#-magic /tmp/live_data_2922/boot/magic \
#-no-desktop -allow-multidot \
#/tmp/live_data_2922/ 2>&1|tee mklog4

#squashfs mount sippai you shori
rm -f /tmp/live_data_$$/base/opt.mo


mkhybrid -v -R -D -o /tmp/testlive.iso -part -hfs -T -r -l -J -sysid PPC -hfs-bless /tmp/live_data_$$/boot -magic /tmp/live_data_$$/boot/magic -map /tmp/live_data_$$/boot/mapping -no-desktop -allow-multidot /tmp/live_data_$$/ 

#mkhybrid -v -R -D -o /tmp/testlive.iso -part -hfs -T -r -l -J -sysid PPC -A "$CDLABEL" -V "$CDLABEL" -hfs-bless /tmp/live_data_$$/boot -map /tmp/live_data_$$/boot/mapping -magic /tmp/live_data_$$/boot/magic -no-desktop -allow-multidot /tmp/live_data_$$/  2>&1|tee mkisolog$$ 


#cdrecord -v speed=4 dev=ATAPI:0,1,0 /tmp/testlive.iso 								  
