#!/bin/bash

#Copy files
HTTPD=/vagrant/httpd

cp $HTTPD/httpd@.service /usr/lib/systemd/system/
cp $HTTPD/httpd-first /etc/sysconfig/
cp $HTTPD/httpd-second /etc/sysconfig/
cp $HTTPD/first.conf /etc/httpd/conf/
cp $HTTPD/second.conf /etc/httpd/conf/

#Start HTTPD Services

sudo systemctl daemon-reload
sudo systemctl start httpd@first
sudo systemctl start httpd@second
