# Цель домашнего задания
# Диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.

## 1. Устанавливаем ВМ через Vagrantfile

После установки проверяем статус nginx и видем что SELinux блокирует работу nginx на не стандартном порту

## РЕШЕНИЕ первое: Спомощью setsebool

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


