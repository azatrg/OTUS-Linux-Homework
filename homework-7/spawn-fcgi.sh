#!/bin/bash

#copy files

SPAWN=/vagrant/spawn-fcgi

cp $SPAWN/spawn-fcgi /etc/sysconfig/
cp $SPAWN/spawn-fcgi.service /etc/systemd/system/

#Start Spawn-FCGI Service

sudo systemctl enable spawn-fcgi
sudo systemctl start spawn-fcgi
