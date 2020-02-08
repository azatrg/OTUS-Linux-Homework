#!/usr/bin/bash

##Install necessary tools

echo Install necessary tools
yum install -y mdadm parted e2fsprogs
## Zero superblocks on disks

echo Zero superblocks on disks
mdadm --zero-superblock --force /dev/sd{b,c,d,e}
##create raid6

echo create raid10
mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}
##label as gpt and create partitions

echo label as gpt and create partitions
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 25%
parted /dev/md0 mkpart primary ext4 25% 50%
parted /dev/md0 mkpart primary ext4 50% 75%
parted /dev/md0 mkpart primary ext4 75% 100%
##Format partiions in ext4

echo Format partiions in ext4
for i in $(seq 1 4); do sudo mkfs.ext4 /dev/md0p$i; done
## create directories and mount partitions

echo create directories and mount partitions
mkdir -p /raid/part{1,2,3,4}
for i in $(seq 1 4); do sudo mount /dev/md0p$i /raid/part$i; done
