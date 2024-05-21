## Vagrant-стенд c OSPF

# Описание домашнего задания

1. Развернуть 3 виртуальные машины
2. Объединить их разными vlan
- настроить OSPF между машинами на базе Quagga;
- изобразить ассиметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

Все дальнейшие действия были проверены при использовании Vagrant 2.2.19, VirtualBox v6.1.26

# Установка пакетов для тестирования и настройки OSPF
```
apt update
apt install vim traceroute tcpdump net-tools
```
Подключаемся по ssh на router1 и настраиваем

2.1 Настройка OSPF между машинами на базе Quagga

Пакет Quagga перестал развиваться в 2018 году. Ему на смену пришёл пакет FRR, он построен на базе Quagga и продолжает своё развитие. В данном руководстве настойка OSPF будет осуществляться в FRR.

Процесс установки FRR и настройки OSPF вручную:
1) Отключаем файерволл ufw и удаляем его из автозагрузки:
```
   systemctl stop ufw 
   systemctl disable ufw
```
2) Добавляем gpg ключ:
```
   curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
```
3) Добавляем репозиторий c пакетом FRR:
```
   echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable > /etc/apt/sources.list.d/frr.list
```
4) Обновляем пакеты и устанавливаем FRR:
```
   sudo apt update
   sudo apt install frr frr-pythontools
```
5) Разрешаем (включаем) маршрутизацию транзитных пакетов:
```
sysctl net.ipv4.conf.all.forwarding=1
```
6) Включаем демон ospfd в FRR
Для этого открываем в редакторе файл /etc/frr/daemons и меняем в нём параметры для пакетов zebra и ospfd на yes:
```
vim /etc/frr/daemons

zebra=yes
ospfd=yes
bgpd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
vrrpd=no
pathd=no
```
В примере показана только часть файла

7) Настройка OSPF
Для настройки OSPF нам потребуется создать файл /etc/frr/frr.conf который будет содержать в себе информацию о требуемых интерфейсах и OSPF. Разберем пример создания файла на хосте router1. 

Для начала нам необходимо узнать имена интерфейсов и их адреса. Сделать это можно с помощью двух способов:
Посмотреть в linux: ip a | grep inet 
```
root@router1:~# ip a | grep "inet " 
    inet 127.0.0.1/8 scope host lo
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
    inet 10.0.10.1/30 brd 10.0.10.3 scope global enp0s8
    inet 10.0.12.1/30 brd 10.0.12.3 scope global enp0s9
    inet 192.168.10.1/24 brd 192.168.10.255 scope global enp0s10
    inet 192.168.50.10/24 brd 192.168.50.255 scope global enp0s16
root@router1:~# 
```
Зайти в интерфейс FRR и посмотреть информацию об интерфейсах
```
root@router1:~# vtysh

Hello, this is FRRouting (version 8.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# show interface brief
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
enp0s3          up      default         10.0.2.15/24
enp0s8          up      default         10.0.10.1/30
enp0s9          up      default         10.0.12.1/30
enp0s10         up      default         192.168.10.1/24
enp0s16         up      default         192.168.50.10/24
lo              up      default         

router1# exit 
root@router1:~# 
```
В обоих примерах мы увидем имена сетевых интерфейсов, их ip-адреса и маски подсети. Исходя из схемы мы понимаем, что для настройки OSPF нам достаточно описать интерфейсы enp0s8, enp0s9, enp0s10 

Создаём файл /etc/frr/frr.conf и вносим в него следующую информацию:
```
!Указание версии FRR
frr version 8.1
frr defaults traditional
!Указываем имя машины
hostname router1
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
!Добавляем информацию об интерфейсе enp0s8
interface enp0s8
 !Указываем имя интерфейса
 description r1-r2
 !Указываем ip-aдрес и маску (эту информацию мы получили в прошлом шаге)
 ip address 10.0.10.1/30
 !Указываем параметр игнорирования MTU
 ip ospf mtu-ignore
 !Если потребуется, можно указать «стоимость» интерфейса
 !ip ospf cost 1000
 !Указываем параметры hello-интервала для OSPF пакетов
 ip ospf hello-interval 10
 !Указываем параметры dead-интервала для OSPF пакетов
 !Должно быть кратно предыдущему значению
 ip ospf dead-interval 30
!
interface enp0s9
 description r1-r3
 ip address 10.0.12.1/30
 ip ospf mtu-ignore
 !ip ospf cost 45
 ip ospf hello-interval 10
 ip ospf dead-interval 30

interface enp0s10
 description net_router1
 ip address 192.168.10.1/24
 ip ospf mtu-ignore
 !ip ospf cost 45
 ip ospf hello-interval 10
 ip ospf dead-interval 30 
!
!Начало настройки OSPF
router ospf
 !Указываем router-id 
 router-id 1.1.1.1
 !Указываем сети, которые хотим анонсировать соседним роутерам
 network 10.0.10.0/30 area 0
 network 10.0.12.0/30 area 0
 network 192.168.10.0/24 area 0 
 !Указываем адреса соседних роутеров
 neighbor 10.0.10.2
 neighbor 10.0.12.2

!Указываем адрес log-файла
log file /var/log/frr/frr.log
default-information originate always
```


Сохраняем изменения и выходим из данного файла. 

Вместо файла frr.conf мы можем задать данные параметры вручную из vtysh. Vtysh использует cisco-like команды.
 
На хостах router2 и router3 также потребуется настроить конфигруационные файлы, предварительно поменяв ip -адреса интерфейсов. 

8) После создания файлов /etc/frr/frr.conf и /etc/frr/daemons нужно проверить, что владельцем файла является пользователь frr. Группа файла также должна быть frr. Должны быть установленны следующие права:
у владельца на чтение и запись
у группы только на чтение
```
ls -l /etc/frr
```
Если права или владелец файла указан неправильно, то нужно поменять владельца и назначить правильные права, например:
```
chown frr:frr /etc/frr/frr.conf 
chmod 640 /etc/frr/frr.conf 
```
9) Перезапускаем FRR и добавляем его в автозагрузку и проверям, что OSPF перезапустился без ошибок

```
root@router1:~# systemctl restart frr

root@router1:~# 
root@router1:~# systemctl enable frr
Synchronizing state of frr.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable frr
root@router1:~# systemctl status frr
● frr.service - FRRouting
     Loaded: loaded (/lib/systemd/system/frr.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-05-21 11:44:00 UTC; 25s ago
       Docs: https://frrouting.readthedocs.io/en/latest/setup.html
   Main PID: 10478 (watchfrr)
     Status: "FRR Operational"
      Tasks: 10 (limit: 1117)
     Memory: 22.1M
     CGroup: /system.slice/frr.service
             ├─10478 /usr/lib/frr/watchfrr -d -F traditional zebra mgmtd ospfd staticd
             ├─10491 /usr/lib/frr/zebra -d -F traditional -A 127.0.0.1 -s 90000000
             ├─10496 /usr/lib/frr/mgmtd -d -F traditional -A 127.0.0.1
             ├─10498 /usr/lib/frr/ospfd -d -F traditional -A 127.0.0.1
             └─10501 /usr/lib/frr/staticd -d -F traditional -A 127.0.0.1

May 21 11:43:55 router1 ospfd[10498]: [VTVCM-Y2NW3] Configuration Read in Took: 00:00:00
May 21 11:43:55 router1 frrinit.sh[10508]: [10508|ospfd] Configuration file[/etc/frr/frr.conf] processing failure: 2
May 21 11:43:55 router1 watchfrr[10478]: [ZJW5C-1EHNT] restart all process 10479 exited with non-zero status 2
May 21 11:44:00 router1 watchfrr[10478]: [QDG3Y-BY5TN] zebra state -> up : connect succeeded
May 21 11:44:00 router1 watchfrr[10478]: [QDG3Y-BY5TN] ospfd state -> up : connect succeeded
May 21 11:44:00 router1 watchfrr[10478]: [QDG3Y-BY5TN] staticd state -> up : connect succeeded
May 21 11:44:00 router1 watchfrr[10478]: [QDG3Y-BY5TN] mgmtd state -> up : connect succeeded
May 21 11:44:00 router1 watchfrr[10478]: [KWE5Q-QNGFC] all daemons up, doing startup-complete notify
May 21 11:44:00 router1 frrinit.sh[10459]:  * Started watchfrr
May 21 11:44:00 router1 systemd[1]: Started FRRouting.
root@router1:~# 
```
Если мы правильно настроили OSPF, то с любого хоста нам должны быть доступны сети:
192.168.10.0/24
192.168.20.0/24
192.168.30.0/24
10.0.10.0/30 
10.0.11.0/30
10.0.13.0/30
