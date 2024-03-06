# Цель домашнего задания
# Диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.

## 1. Устанавливаем ВМ через Vagrantfile

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
