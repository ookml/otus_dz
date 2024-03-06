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

смотрим логи /var/log/audit/audit.log
```

```
