# Цель домашнего задания
# Диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.


# 1. Запуск nginx на нестандартном порту 3-мя разными способами 

## Устанавливаем ВМ через Vagrantfile в репозитории

После установки проверяем статус nginx и видем что SELinux блокирует работу nginx на не стандартном порту

## РЕШЕНИЕ первое: С помощью setsebool

В начеле проверяем что отключен firewall, что конфигурация nginx настроена без ошибок и проверяем режим работы SELinux режи должен быть "Enforcing"
```
[root@selinux ~]# systemctl status firewalld.service 
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
[root@selinux ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@selinux ~]# getenforce 
Enforcing
```
Разрешаем в SELinux работу на не стандартном порту TCP 4881

Находим в логе время и в которое было записанно сообщение у меня ето например 1709708791.442:818
```
[root@selinux ~]# cat /var/log/audit/audit.log | grep 4881
type=AVC msg=audit(1709708791.442:818): avc:  denied  { name_bind } for  pid=2866 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=AVC msg=audit(1709708876.409:856): avc:  denied  { name_bind } for  pid=2972 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=AVC msg=audit(1709708920.435:862): avc:  denied  { name_bind } for  pid=2996 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
```
С помощью утилиты audit2why ищим проблему
```
[root@selinux ~]# grep 1709708791.442:818 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1709708791.442:818): avc:  denied  { name_bind } for  pid=2866 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
в выводе видим что нужно поменять значение nis_enabled 1

Меняем, перезапускаем и проверяем NGINX
```
[root@selinux ~]# setsebool -P nis_enabled on
[root@selinux ~]# systemctl restart nginx.service 
[root@selinux ~]# systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-03-06 07:43:25 UTC; 8s ago
  Process: 3382 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3380 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3379 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3384 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3384 nginx: master process /usr/sbin/nginx
           └─3386 nginx: worker process

Mar 06 07:43:25 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 06 07:43:25 selinux nginx[3380]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 06 07:43:25 selinux nginx[3380]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 06 07:43:25 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Проверка статуса 
```
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
```
Возвращаем запрет порта 4881 обратно для теста второго варианта
```
[root@selinux ~]# setsebool -P nis_enabled off
[root@selinux ~]# getsebool -a | grep nis_enabled
nis_enabled --> off
```
## РЕШЕНИЕ второе: c помощью добавления нестандартного порта в имеющийся тип

Ищем имеющийся тип для http трафика
```
[root@selinux ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
Добавим порт в тип http_port_t
```
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
Перезапускаем службу nginx и проверяем
```
[root@selinux ~]systemctl restart nginx.service 
[root@selinux ~]systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-03-06 07:53:45 UTC; 3s ago
  Process: 3439 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3437 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3436 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3441 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3441 nginx: master process /usr/sbin/nginx
           └─3443 nginx: worker process

Mar 06 07:53:45 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 06 07:53:45 selinux nginx[3437]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 06 07:53:45 selinux nginx[3437]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 06 07:53:45 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Удаляем нестандартный порт для теста 3 
```
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```

## РЕШЕНИЕ третье: c помощью формирования и установки модуля SELinux

Используем утилиту audit2allow для того, чтобы найти в логах проблему и разрешить работу на нестандартном порту
```
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```
Audit2allow сформировал модуль и сообщяет команду с помощью кторой можно применить данный модуль
```
[root@selinux ~]# semodule -i nginx.pp
```
Перезапускаем службу nginx и проверяем
```
[root@selinux ~]# systemctl restart nginx.service 
[root@selinux ~]# systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Wed 2024-03-06 08:03:15 UTC; 2s ago
  Process: 3525 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3521 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3520 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3527 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3527 nginx: master process /usr/sbin/nginx
           └─3529 nginx: worker process

Mar 06 08:03:15 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 06 08:03:15 selinux nginx[3521]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 06 08:03:15 selinux nginx[3521]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 06 08:03:15 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Просмотр всех установленных модулей
```
[root@selinux ~]# semodule -l
watchdog        1.8.0
wdmd    1.1.0
webadm  1.2.0
webalizer       1.13.0
wine    1.11.0
wireshark       2.4.0
xen     1.13.0
xguest  1.2.0
xserver 3.9.4
zabbix  1.6.0
zarafa  1.2.0
zebra   1.13.0
zoneminder      1.0.0
zosremote       1.2.0
```
Для удаления модуля команды 
```
[root@selinux ~]# semodule -r nginx 
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
```
# 2. Обеспечение работоспособности приложения при включенном SELinux

Для того, чтобы развернуть стенд потребуется хост, с установленным git и ansible.
```
root@LinuxMint:~# ansible --version
ansible 2.10.8
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  executable location = /usr/bin/ansible
  python version = 3.10.12 (main, Nov 20 2023, 15:14:05) [GCC 11.4.0]
root@LinuxMint:~# git --version
git version 2.34.1
```
далее 

Выполним клонирование репозитория https://github.com/mbfx/otus-linux-adm.git
```
root@LinuxMint:~# git clone https://github.com/mbfx/otus-linux-adm.git
Клонирование в «otus-linux-adm»...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Получение объектов: 100% (558/558), 1.38 МиБ | 1.09 МиБ/с, готово.
Определение изменений: 100% (140/140), готово.
```
Переходим в каталог и разварачиваем 2 виртуалки, проверяем статус
```
root@LinuxMint:~# cd otus-linux-adm/selinux_dns_problems/
root@LinuxMint:~/otus-linux-adm/selinux_dns_problems# vagrant up
root@LinuxMint:~/otus-linux-adm/selinux_dns_problems# vagrant status
Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```
подключаемся на клиент 
```
root@LinuxMint:~/otus-linux-adm/selinux_dns_problems# vagrant ssh client
```
Попробуем внести изменения в зону: nsupdate -k /etc/named.zonetransfer.key
```
[vagrant@client ~]$ sudo -i
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key 
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```
Выдает ошибку, смотрим лог SELinux
```
[root@client ~]# cat /var/log/audit/audit.log | audit2why
[root@client ~]# 
```
Видим что и тут ошибок нету 

Не закрываем сессию клиента и подключемся к серверу

Проверяем логи SELinux
```
[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1709713700.785:1911): avc:  denied  { create } for  pid=5129 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t.

Проверим данную проблему в каталоге /etc/named:
```
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```
Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды: sudo semanage fcontext -l 

```
[root@ns01 ~]# sudo semanage fcontext -l | grep named
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0 
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 
...
```
Изменим тип контекста безопасности для каталога /etc/named:
```
[root@ns01 ~]# chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```
Попробуем снова внести изменения с клиента: 
```
[root@ns01 ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
```
```[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 30144
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; AUTHORITY SECTION:
ddns.lab.               600     IN      SOA     ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Wed Mar 06 08:43:01 UTC 2024
;; MSG SIZE  rcvd: 91
```
Видим, что изменения применились. Попробуем перезагрузить хосты и ещё раз сделать запрос с помощью dig: 
```
[root@client ~]#  dig @192.168.50.10 www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 3500
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; AUTHORITY SECTION:
ddns.lab.               600     IN      SOA     ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Wed Mar 06 08:44:14 UTC 2024
;; MSG SIZE  rcvd: 91
```

Для того, чтобы вернуть правила обратно, можно ввести команду: restorecon -v -R /etc/named
```
[vagrant@ns01 ~]$ sudo -i
[root@ns01 ~]# restorecon -v -R /etc/named
restorecon reset /etc/named context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.dns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic context unconfined_u:object_r:named_zone_t:s0->unconfined_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.jnl context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.newdns.lab context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
restorecon reset /etc/named/named.50.168.192.rev context system_u:object_r:named_zone_t:s0->system_u:object_r:etc_t:s0
```

