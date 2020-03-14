#!/bin/bash

## Variables

REPOPATH=/usr/share/nginx/html/repo
RPMPATH=/vagrant/RPM
### Install nginx

yum install -y epel-release && sudo yum install -y nginx

###Create Dir for repo

mkdir $REPOPATH
cp -r $RPMPATH/* $REPOPATH

###Copy nginx config Nginx settings

cp -f /vagrant/nginx.conf /etc/nginx/

### Start nginx

systemctl enable nginx
systemctl start nginx



# Create REPO
createrepo $REPOPATH
## Add repo to YUM

cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=azat-otus
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

