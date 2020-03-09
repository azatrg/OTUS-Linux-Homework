#!/bin/bash

# Copy files
WATCH=/vagrant/watcher
chmod a+x $WATCH/watcher.sh

cp $WATCH/watcher.conf /etc/sysconfig/
cp $WATCH/watcher.log /var/log/
cp $WATCH/watcher.sh /opt/
cp $WATCH/watcher.service /usr/lib/systemd/system/
cp $WATCH/watcher.timer /usr/lib/systemd/system

#start service and timer
sudo systemctl daemon-reload
sudo systemctl enable watcher.timer
sudo systemctl start watcher.timer
sudo systemctl enable watcher.service
sudo systemctl start watcher.service


