#!/bin/bash

#install tools to build kernel and wget(to download kernel archive)
yum -y groupinstall "Development Tools"
yum install -y hmaccalc zlib-devel binutils-devel elfutils-libelf-devel bc openssl-devel wget
#download kernel and extract it
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.tar.xz
tar -Jxvf linux-5.5.tar.xz
cd linux-5.5

#copy old kernel config and
cp /boot/config* .config &&
#Build new kernel from sources
make olddefconfig &&
make -j 4 &&
make -j 4 modules &&
make -j 4 modules_install &&
make -j 4 install
# Remove older kernels (Only for demo! Not Production!)
rm -f /boot/*3.10*
# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Reboot VM
shutdown -r now
