#!/bin/bash
mdadm --zero-superblock --force /dev/sd{a,b,c,d,e}
mdadm --create --verbose /dev/md0 -l6 -n5 /dev/sd{a,b,c,d,e} <<EOF
yes
EOF
