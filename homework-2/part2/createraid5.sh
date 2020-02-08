#!/usr/bin/bash

##Install necessary tools

echo Install necessary tools
yum install -y mdadm parted e2fsprogs
## Zero superblocks on disks

echo Zero superblocks on disks
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
##create raid6

echo create raid6
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}

# Create mdadm.conf
echo create mdadm.conf
mkdir /etc/mdadm
echo "DEVICE partitions" | sudo tee -a /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf



##label as gpt and create partitions

echo label as gpt and create partitions
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
##Format partiions in ext4

echo Format partiions in ext4
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
## create directories and mount partitions

echo create directories and mount partitions
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
