# Vagrant-стенд c LDAP на базе FreeIPA

## Описание домашнего задания
1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3)* Настроить аутентификацию по SSH-ключам
4)** Firewall должен быть включен на сервере и на клиенте


После создания Vagrantfile, запустим виртуальные машины командой vagrant up. Будут созданы 3 виртуальных машины с ОС CentOS . Каждая ВМ будет иметь по 2ГБ ОЗУ и по одному ядру CPU. 

Начнем настройку FreeIPA-сервера: 
- Установим часовой пояс: timedatectl set-timezone Europe/Moscow
- Установим утилиту chrony: yum install -y chrony
- Запустим chrony и добавим его в автозагрузку: systemctl enable chronyd —now
- Если требуется, поменяем имя нашего сервера: hostnamectl set-hostname <имя сервера>
- В нашей лабораторной работе данного действия не требуется, так как уже указаны корректные имена в Vagrantfile
- Выключим Firewall: systemctl stop firewalld
- Отключаем автозапуск Firewalld: systemctl disable firewalld
- Остановим Selinux: setenforce 0
- Поменяем в файле /etc/selinux/config, параметр Selinux на disabled
  vi /etc/selinux/config
```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```
- Для дальнейшей настройки FreeIPA нам потребуется, чтобы DNS-сервер хранил запись о нашем LDAP-сервере. В рамках данной лабораторной работы мы не будем настраивать отдельный DNS-сервер и просто добавим запись в файл /etc/hosts

vi /etc/hosts
```
127.0.0.1   localhost localhost.localdomain 
127.0.1.1 ipa.otus.lan ipa
192.168.57.10 ipa.otus.lan ipa
```
- Установим модуль DL1: yum install -y @idm:DL1
- Установим FreeIPA-сервер: yum install -y ipa-server

- Запустим скрипт установки: ipa-server-install
Далее, нам потребуется указать параметры нашего LDAP-сервера, после ввода каждого параметра нажимаем Enter, если нас устраивает параметр, указанный в квадратных скобках, то можно сразу нажимать Enter:
```
Do you want to configure integrated DNS (BIND)? [no]: no
Server host name [ipa.otus.lan]: <Нажимаем Enter>
Please confirm the domain name [otus.lan]: <Нажимем Enter>
Please provide a realm name [OTUS.LAN]: <Нажимаем Enter>
Directory Manager password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
IPA admin password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
NetBIOS domain name [OTUS]: <Нажимаем Enter>
Do you want to configure chrony with NTP server or pool address? [no]: no
The IPA Master Server will be configured with:
Hostname:       ipa.otus.lan
IP address(es): 192.168.57.10
Domain name:    otus.lan
Realm name:     OTUS.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=OTUS.LAN
Subject base: O=OTUS.LAN
Chaining:     self-signed
Проверяем параметры, если всё устраивает, то нажимаем yes
Continue to configure the system with these values? [no]: yes

```
Далее начнется процесс установки. Процесс установки занимает примерно 10-15 минут (иногда время может быть другим). Если мастер успешно выполнит настройку FreeIPA то в конце мы получим сообщение: 
The ipa-server-install command was successful

## Если выдаст ошибку ipapython.admintool: ERROR    CA did not start in 300.0s
- ipapython.admintool: ERROR    The ipa-server-install command failed. See /var/log/ipaserver-install.log for more information

РЕШЕНИЕ: yum update nss

После удалите ipa-server-install --uninstall и установите заново ipa-server-install --uninstall

При вводе параметров установки мы вводили 2 пароля:

- Directory Manager password — это пароль администратора сервера каталогов, У этого пользователя есть полный доступ к каталогу.
- IPA admin password — пароль от пользователя FreeIPA admin

После успешной установки FreeIPA, проверим, что сервер Kerberos может выдать нам билет:
```
[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN: 
[root@ipa ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@OTUS.LAN

Valid starting     Expires            Service principal
06/26/24 11:02:11  06/27/24 11:01:46  krbtgt/OTUS.LAN@OTUS.LAN
```
Мы можем зайти в Web-интерфейс нашего FreeIPA-сервера, для этого на нашей хостой машине в браузере вводим https://ipa.otus.lan/ipa/ui/

![image](https://github.com/ookml/otus_dz/assets/21999102/ccbdd85f-fc3f-4a3d-83dd-84d5c54afc5a)

Откроется окно управления FreeIPA-сервером. В имени пользователя укажем admin, в пароле укажем наш IPA admin password и нажмём войти. 

![image](https://github.com/ookml/otus_dz/assets/21999102/2a5de09e-6841-4127-a8a1-3c26f2248b1c)


