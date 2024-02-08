#!/bin/bash

sudo -i
yum install -y \
redhat-lsb-core \
wget \
rpmdevtools \
rpm-build \
createrepo \
yum-utils \
gcc

wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm

rpm -i nginx-1.*

wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip

unzip OpenSSL_1_1_1-stable.zip

sudo yum-builddep -y rpmbuild/SPECS/nginx.spec

rpmbuild -bb rpmbuild/SPECS/nginx.spec

sudo yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm

sudo systemctl start nginx

sudo mkdir /usr/share/nginx/html/repo
sudo cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget

sudo wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O /usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm

createrepo /usr/share/nginx/html/repo/

sudo chmod 0777 /etc/nginx/conf.d/default.conf 
sudo echo "autoindex on;" >> /etc/nginx/conf.d/default.conf
sudo nginx -s reload

sudo chmod 0777 /etc/yum.repos.d/
sudo cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF


