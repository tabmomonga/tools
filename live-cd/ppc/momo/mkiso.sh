#!/bin/bash

CDLABEL=livemomonga

rm -f /tmp/live_data_$1/base/opt.mo

mkhybrid -v -R -D -o /tmp/testlive.iso -part -hfs -T -r -l -J -sysid PPC -A "$CDLABEL" -V "$CDLABEL" -hfs-bless /tmp/live_data_$1/boot -map /tmp/live_data_$1/boot/mapping -magic /tmp/live_data_$1/boot/magic -no-desktop -allow-multidot /tmp/live_data_$1/ 2>&1|tee mkisolog$1 

