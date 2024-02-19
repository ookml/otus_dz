# Инициализация системы. Systemd

## Задачи
Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).
Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

## Cоздаём файл с конфигурацией
```
[root@Systemd ~]# cat /etc/sysconfig/watchlog 
# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```
## Создаем лог 

touch /var/log/watchlog.log 

## Cоздаем скрипт
```
[root@Systemd ~]# cat /opt/watchlog.sh 
#!/bin/bash

WORD=
LOG=
DATE=Sat Feb 17 17:21:03 UTC 2024

if grep   &> /dev/null
then
logger ": I found word, Master!"
else
exit 0
fi
```
## Добавим права на запуск файла

chmod +x /opt/watchlog.sh

## Создадим юнит для сервиса
```
[root@Systemd ~]# cat /etc/systemd/system/watchlog.service 
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh 
```
## Создадим юнит для таймера
```
[root@Systemd ~]# cat /etc/systemd/system/watchlog.timer   

[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```
## Стартуем timer и проверяем
```
[root@Systemd ~]# systemctl start watchlog.timer 
[root@Systemd ~]# tail -f /var/log/messages 
Feb 17 17:08:50 localhost systemd-logind: Removed session 2.
Feb 17 17:08:50 localhost systemd: Removed slice User Slice of vagrant.
Feb 17 17:08:57 localhost systemd: Created slice User Slice of vagrant.
Feb 17 17:08:57 localhost systemd: Started Session 4 of user vagrant.
Feb 17 17:08:57 localhost systemd-logind: New session 4 of user vagrant.
Feb 17 17:24:14 localhost systemd: Starting Cleanup of Temporary Directories...
Feb 17 17:24:14 localhost systemd: Started Cleanup of Temporary Directories.
Feb 17 17:45:45 localhost systemd: Started Run watchlog script every 30 second.
```
## Устанавливаем spawn-fcgi и необходимые для него пакеты

yum install epel-release -y && yum install spawn-fcgi php php-cli
mod_fcgid httpd -y

## Создаем INIT скрипт

```
[root@Systemd ~]# cat /etc/rc.d/init.d/spawn-fcgi 
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s  -S -M 0600 -C 32 -F 1 -- /usr/bin/php-c>
```
## Создаем юнит файл

```
[root@Systemd ~]# cat /etc/systemd/system/spawn-fcgi.service 
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n 
KillMode=process

[Install]
```
## Убеждаемся, что все успешно работает:
```
[root@Systemd ~]# systemctl daemon-reload
[root@Systemd ~]# systemctl start spawn-fcgi
[root@Systemd ~]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2024-02-18 11:53:05 UTC; 5s ago
 Main PID: 23941 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
```
## Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

```
root@Systemd ~]# cat /usr/lib/systemd/system/httpd.service 
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service

After=network.target remote-fs.target nss-lookup.target httpd-
init.service

Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
## Конфиги для юнитов
```
[root@Systemd ~]# grep -P "^OPTIONS" /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
[root@Systemd ~]# grep -P "^OPTIONS" /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```
## Настройки PID файлов 
```
[root@Systemd ~]# grep -P "^PidFile|^Listen" /etc/httpd/conf/first.conf
PidFile "/var/run/httpd-first.pid"
Listen 80
[root@Systemd ~]# grep -P "^PidFile|^Listen" /etc/httpd/conf/second.conf
PidFile "/var/run/httpd-second.pid"
Listen 8080
```
## Стартуем службы
```
[root@Systemd ~]# systemctl start httpd@first
[root@Systemd ~]# systemctl start httpd@second
```
## Проверяем что все работает
```
[root@Systemd ~]# ss -ntlp | grep httpd
LISTEN     0      128       [::]:8080                  [::]:*                   users:(("httpd",pid=24843,fd=4),("httpd",pid=24842,fd=4),("httpd",pid=24841,fd=4),("httpd",pid=24840,fd=4),("httpd",pid=24839,fd=4),("httpd",pid=24838,fd=4),("httpd",pid=24837,fd=4))
LISTEN     0      128       [::]:80                    [::]:*                   users:(("httpd",pid=24830,fd=4),("httpd",pid=24829,fd=4),("httpd",pid=24828,fd=4),("httpd",pid=24827,fd=4),("httpd",pid=24826,fd=4),("httpd",pid=24825,fd=4),("httpd",pid=24824,fd=4))
```
