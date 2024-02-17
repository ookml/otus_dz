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


