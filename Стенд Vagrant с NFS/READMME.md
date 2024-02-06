# Стенд Vagrant с NFS
## Настройка сервера                                                                        

1. ### Доустановка компонентов
   yum install nfs-utils
3. ### Включаем Firewall
     systemctl enable firewalld --now 
4. ### Разрешаем доступ к NFS
     firewall-cmd --add-service="nfs3" \
     --add-service="rpc-bind" \
     --add-service="mountd" \
     --permanent 
     firewall-cmd --reload

5. ### Включаем сервер NFS
     systemctl enable nfs --now 
6. ### Cоздаём и настраиваем директорию
   mkdir -p /srv/share/upload 
   chown -R nfsnobody:nfsnobody /srv/share 
   chmod 0777 /srv/share/upload 

7. ### Помещаем в файл exports
   cat << EOF > /etc/exports 
   /srv/share 172.16.0.20/32(rw,sync,root_squash)
   EOF
8. ### Экспортируем ранее созданную директорию
[root@nfss ~]# exportfs -r

[root@nfss ~]# exportfs -s

/srv/share  172.16.0.25/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
## Настраиваем клиент NFS 

1. ### Доустановка компонентов
    yum install nfs-utils 

2. ### Включаем Firewall
    systemctl enable firewalld --now 
3. ### добавляем строку и перезагружаем 
    echo "172.16.0.20:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

    systemctl daemon-reload 

    systemctl restart remote-fs.target 

    [root@nfsc ~]# mount | grep mnt

    systemd-1 on /mnt type autofs (rw,relatime,fd=46,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=46324)
    172.16.0.20:/srv/share/ on /mnt type nfs 
    (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=172.16.0.20,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=172.16.0.20)

 ## Вывод команд, на то что все работает
   На сервере в каталоге Upload зодаем файл и смотрим что он добавился на клиенте 
### На сервере
 [root@nfss ~]# cd /srv/share/upload/
 
 [root@nfss upload]# touch check_file

### На клиенте 
 [root@nfsc ~]# ls -l /mnt/upload/
 
 total 0
 -rw-r--r--. 1 root root 0 Feb  6 07:44 check_file
 
 [root@nfsc ~]# cd /mnt/upload/
 
 [root@nfsc upload]# touch client_file
 
 [root@nfsc upload]# ls
 
 check_file  client_file
 ### После перезагрузки сервера проверяем файлы, firewall, монтирование.
 [vagrant@nfss ~]$ ls -l /srv/share/upload/
 
 total 0
-rw-r--r--. 1 root      root      0 Feb  6 07:44 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  6 07:45 client_file

[vagrant@nfss ~]$ systemctl status firewalld

● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2024-02-06 07:48:12 UTC; 1min 59s ago
     Docs: man:firewalld(1)
 Main PID: 388 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─388 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

 [root@nfss ~]# exportfs -s

/srv/share  172.16.0.25/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

[root@nfss ~]# showmount -a 172.16.0.20

All mount points on 172.16.0.20:
172.16.0.25:/srv/share

### Проверяем на клиенте после его перезагрузки 
[root@nfsc ~]# showmount -a 172.16.0.20

All mount points on 172.16.0.20:

[root@nfsc ~]# cd /mnt/upload/

[root@nfsc upload]# mount | grep mnt

systemd-1 on /mnt type autofs (rw,relatime,fd=26,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10895)
172.16.0.20:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=172.16.0.20,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=172.16.0.20)

[root@nfsc upload]# ls -l

total 0
-rw-r--r--. 1 root      root      0 Feb  6 07:44 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb  6 07:45 client_file

[root@nfsc upload]# touch final_check


