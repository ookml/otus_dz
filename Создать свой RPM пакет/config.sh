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

sudo wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
echo "Древо коталогов"
rpm -i nginx-1.*
echo "END"
#sudo cp -R /root/rpmbuild/ /home/vagrant/

sudo wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip

sudo unzip OpenSSL_1_1_1-stable.zip

sudo cp -R openssl-OpenSSL_1_1_1-stable /root/

sudo yum-builddep -y /root/rpmbuild/SPECS/nginx.spec

sudo rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec

sudo yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm

sudo systemctl start nginx
sudo mkdir /usr/share/nginx/html/repo
sudo cp /root/rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/

sudo createrepo /usr/share/nginx/html/repo/

sudo chmod 0777 /etc/nginx/conf.d/default.conf
: > /etc/nginx/conf.d/default.conf

sudo cat >> /etc/nginx/conf.d/default.conf << EOF
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}

EOF

#sudo echo "autoindex on;" >> /etc/nginx/conf.d/default.conf
sudo nginx -s reload

#sudo chmod 0777 /etc/yum.repos.d/otus.repo

sudo cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

#sudo echo " > [otus] > name=otus-linux > baseurl=http://localhost/repo > gpgcheck=0 > enabled=1 " >> /etc/yum.repos.d/otus.repo

