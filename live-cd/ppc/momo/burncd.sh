#!/bin/bash

cdrecord dev=ATAPI:0,1,0 --blank=fast;
cdrecord -v speed=4 dev=ATAPI:0,1,0 testlive.iso  
