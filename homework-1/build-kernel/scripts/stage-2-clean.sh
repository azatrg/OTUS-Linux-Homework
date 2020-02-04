#!/bin/bash

# clean all
yum groups remove -y "Development Tools"
yum remove -y hmaccalc zlib-devel binutils-devel elfutils-libelf-devel bc openssl-devel wget
yum update -y
yum clean all


# Install vagrant default key
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh


# Remove temporary files
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm -rf /vagrant/home/*.iso
rm  -f ~/.bash_history
rm  -f /home/vagrant/linux-5.5.tar.xz
rm  -rf /home/vagrant/linux-5.5
history -c

rm -rf /run/log/journal/*

# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
grub2-set-default 1
echo "###   Hi from secone stage" >> /boot/grub2/grub.cfg

