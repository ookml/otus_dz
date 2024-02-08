# Домашние задание создать свой RPM пакет

1. ## Скачать пакет
    wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
2. ## Создаем древо каталогов для сборки
    rpm -i nginx-1.*
3. ## Качаем архив и расспаковываем
    wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip

    unzip OpenSSL_1_1_1-stable.zip 
5. ## Доставим зависимости
    yum-builddep rpmbuild/SPECS/nginx.spec
6. ## Сборка RPM пакета
   rpmbuild -bb rpmbuild/SPECS/nginx.spec

Выполняется(%clean): /bin/sh -e /var/tmp/rpm-tmp.EzyTEd
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.2
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.2-1.el7.ngx.x86_64
+ exit 0
7. ## Проверяем что пакет создан
  
   [root@webserver ~]# ll rpmbuild/RPMS/x86_64/

итого 2588

-rw-r--r--. 1 root root  808408 фев  8 05:22 nginx-1.20.2-1.el7.ngx.x86_64.rpm

-rw-r--r--. 1 root root 1836144 фев  8 05:22 nginx-debuginfo-1.20.2-1.el7.ngx.x86_64.rpm

8. ## Установка пакета 

yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm 

----------------------------------------------------------------------
  Проверка    : 1:nginx-1.20.2-1.el7.ngx.x86_64                                                                                                         1/1 

Установлено:
  nginx.x86_64 1:1.20.2-1.el7.ngx                                                                                                                           

Выполнено!

   [root@webserver ~]# systemctl start nginx

  [root@webserver ~]# systemctl status nginx

● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Чт 2024-02-08 05:44:45 UTC; 6s ago
     Docs: http://nginx.org/en/docs/
  Process: 12520 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 12521 (nginx)
   CGroup: /system.slice/nginx.service
           ├─12521 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─12522 nginx: worker process

# Создаем свой репозиторий и разместим туда ранее собранный RPM

    [root@webserver ~]# mkdir /usr/share/nginx/html/repo

    [root@webserver ~]# cp rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/

    [root@webserver ~]# wget https://downloads.percona.com/downloads/percona-distribution-mysql-ps/percona-distribution-mysql-ps-8.0.28/binary/redhat/8/x86_64/percona-orchestrator-3.2.6-2.el8.x86_64.rpm -O/usr/share/nginx/html/repo/percona-orchestrator-3.2.6-2.el8.x86_64.rpm

    [root@webserver ~]# createrepo /usr/share/nginx/html/repo/
  
    Spawning worker 0 with 2 pkgs
    Workers Finished
    Saving Primary metadata
    Saving file lists metadata
    Saving other metadata
    Generating sqlite DBs
    Sqlite DBs complete

## Добавляем в autoindex on;

     [root@webserver ~]# cat /etc/nginx/conf.d/default.conf | grep autoindex
       
        autoindex on;

## Проверяем синтаксис и перезагружаем nginx

    [root@webserver ~]# nginx -t

    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

    [root@webserver ~]# nginx -s reload
    
    [root@webserver ~]# systemctl status nginx
    
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Чт 2024-02-08 05:44:45 UTC; 19min ago
     Docs: http://nginx.org/en/docs/
  Process: 12520 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 12521 (nginx)
   CGroup: /system.slice/nginx.service
           ├─12521 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─12651 nginx: worker process

## Проверяем что все работает 

    [root@webserver ~]# curl -a http://localhost/repo/

    <html>
    <head><title>Index of /repo/</title></head>
    <body>
    <h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
    <a href="repodata/">repodata/</a>                                          08-Feb-2024 05:53                   -
    <a href="nginx-1.20.2-1.el7.ngx.x86_64.rpm">nginx-1.20.2-1.el7.ngx.x86_64.rpm</a>                  08-Feb-2024 05:50              808408
    <a href="percona-orchestrator-3.2.6-2.el8.x86_64.rpm">percona-orchestrator-3.2.6-2.el8.x86_64.rpm</a>        16-Feb-2022 15:57             5222976
    </pre><hr></body>
    </html>


    [root@webserver ~]# cat >> /etc/yum.repos.d/otus.repo << EOF
    > [otus]
    > name=otus-linux
    > baseurl=http://localhost/repo
    > gpgcheck=0
    > enabled=1
    > EOF
       
    [root@webserver ~]# yum repolist enabled | grep otus
    otus                                   otus-linux                           2

    [root@webserver ~]# yum list | grep otus
    percona-orchestrator.x86_64                 2:3.2.6-2.el8              otus     
    [root@webserver ~]# yum install percona-orchestrator.x86_64 -y
