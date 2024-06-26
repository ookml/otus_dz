# VLAN и LACP

## Описание домашнего задания
в Office1 в тестовой подсети появляется сервера с доп интерфейсами и адресами
в internal сети testLAN: 
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1 
- testServer2- 10.10.10.1

## Равести вланами:
- testClient1 <-> testServer1
- testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов


1. vagrant up
2. Перейдем в папку ansible и создадим файл hosts.
```
   [Otus]
inetRouter ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/inetRouter/virtualbox/private_key bond_ip=192.168.255.1
centralRouter ansible_host=192.168.56.11 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/centralRouter/virtualbox/private_key bond_ip=192.168.255.2
office1Router ansible_host=192.168.56.20 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/office1Router/virtualbox/private_key 
testClient1 ansible_host=192.168.56.21 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/testClient1/virtualbox/private_key vlan_id=1 vlan_ip=10.10.10.254
testServer1 ansible_host=192.168.56.22 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/testServer1/virtualbox/private_key vlan_id=1 vlan_ip=10.10.10.1
testClient2 ansible_host=192.168.56.31 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/testClient2/virtualbox/private_key vlan_id=2 vlan_ip=10.10.10.254
testServer2 ansible_host=192.168.56.32 ansible_user=vagrant ansible_ssh_private_key_file=../.vagrant/machines/testServer2/virtualbox/private_key vlan_id=2 vlan_ip=10.10.10.1
```
3. Создадим файл provision.yml
```
- name: Base set up
  #Настройка производится на всех хостах
  hosts: all
  become: yes
  tasks:
  #Установка приложений на RedHat-based системах
  - name: install softs on CentOS
    yum:
      name:
        - vim
        - traceroute
        - tcpdump
        - net-tools
      state: present
      update_cache: true
    when: (ansible_os_family == "RedHat")
  
  #Установка приложений на Debiam-based системах
  - name: install softs on Debian-based
    apt:
      name: 
        - vim
        - traceroute
        - tcpdump
        - net-tools
      state: present
      update_cache: true
    when: (ansible_os_family == "Debian")
```
4. Запустим provison.yml для предварительной настройки всех хостов.
```
cd ansible
ansible-playbook provision.yml
```
## Настройка VLAN с помощью ansible
1. Создадим vlan1.yml
```
- name: set up vlan1
  #Настройка будет производиться на хостах testClient1 и testServer1
  hosts: testClient1,testServer1
  #Настройка производится от root-пользователя
  become: yes
  tasks:
  #Добавление темплейта в файл /etc/sysconfig/network-scripts/ifcfg-vlan1
  - name: set up vlan1
    template:
      src: ifcfg-vlan1.j2
      dest: /etc/sysconfig/network-scripts/ifcfg-vlan1
      owner: root
      group: root
      mode: 0644
  
  #Перезапуск службы NetworkManager
  - name: restart network for vlan1
    service:
      name: NetworkManager
      state: restarted
```
2. Файл шаблона ifcfg-vlan1.j2
```
VLAN=yes
TYPE=Vlan
PHYSDEV=eth1
VLAN_ID={{ vlan_id }}
VLAN_NAME_TYPE=DEV_PLUS_VID_NO_PAD
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR={{ vlan_ip }}
PREFIX=24
NAME=vlan{{ vlan_id }}
DEVICE=eth1.{{ vlan_id }}
ONBOOT=yes
```
3. Запустим настройку vlan1 на testClient1 и testServer1
```
ansible-playbook vlan1.yml -l testClient1 testServer1
```
4. Подключимся к testClient1 и проверим testServer1
```
vagrant ssh testClient1
```
```
root@LinuxMint:/var/vlan/ansible# vagrant ssh testClient1
Last login: Thu Jun 20 07:40:04 2024 from 192.168.56.1
[vagrant@testClient1 ~]$ sudo -i
[root@testClient1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 86360sec preferred_lft 86360sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:f3:4f:5d brd ff:ff:ff:ff:ff:ff
    inet6 fe80::cfed:585d:2852:e7f6/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:52:8f:2f brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.21/24 brd 192.168.56.255 scope global noprefixroute eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe52:8f2f/64 scope link 
       valid_lft forever preferred_lft forever
5: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:f3:4f:5d brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fef3:4f5d/64 scope link 
       valid_lft forever preferred_lft forever
[root@testClient1 ~]# ping 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=1.49 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.838 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.933 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.902 ms
64 bytes from 10.10.10.1: icmp_seq=5 ttl=64 time=0.914 ms

```
## Настройка LACP
1. Настроим LACP между хостами inetRouter и centralRouter
- Создадим lacp.yml
```
- name: set up bond0
  hosts: inetRouter,centralRouter
  become: yes
  tasks:
  - name: set up ifcfg-bond0
    template:
      src: ifcfg-bond0.j2
      dest: /etc/sysconfig/network-scripts/ifcfg-bond0
      owner: root
      group: root
      mode: 0644
  
  - name: set up eth1,eth2
    copy: 
      src: "{{ item }}" 
      dest: /etc/sysconfig/network-scripts/
      owner: root
      group: root
      mode: 0644
    with_items:
      - ifcfg-eth1.j2
      - ifcfg-eth2.j2
  #Перезагрузка хостов 
  - name: restart hosts for bond0
    reboot:
      reboot_timeout: 3600
```
2. Создадим файлы шаблонов для eth1 и eth2.
- ifcfg-eth1.j2
```
#Имя физического интерфейса
DEVICE=eth1
#Включать интерфейс при запуске системы
ONBOOT=yes
#Отключение DHCP-клиента
BOOTPROTO=none
#Указываем, что порт часть bond-интерфейса
MASTER=bond0
#Указыаваем роль bond
SLAVE=yes
NM_CONTROLLED=yes
USERCTL=no
```
- ifcfg-eth2.j2
```
#Имя физического интерфейса
DEVICE=eth2
#Включать интерфейс при запуске системы
ONBOOT=yes
#Отключение DHCP-клиента
BOOTPROTO=none
#Указываем, что порт часть bond-интерфейса
MASTER=bond0
#Указыаваем роль bond
SLAVE=yes
NM_CONTROLLED=yes
USERCTL=no
```
- ifcfg-bond0.j2
```
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
IPADDR={{ bond_ip }}
NETMASK=255.255.255.252
ONBOOT=yes
BOOTPROTO=static
BONDING_OPTS="mode=1 miimon=100 fail_over_mac=1"
NM_CONTROLLED=yes
USERCTL=no
```
3. Подключимся к inetRouter и проверим centralRouter, затем отключим eth1 на CentralRouter и проверим ping.
```
root@LinuxMint:/var/vlan/ansible# vagrant ssh inetRouter
Last login: Thu Jun 20 08:16:53 2024 from 192.168.56.1
[vagrant@inetRouter ~]$ sudo -i
[root@inetRouter ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:4d:77:d3 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 86296sec preferred_lft 86296sec
    inet6 fe80::5054:ff:fe4d:77d3/64 scope link 
       valid_lft forever preferred_lft forever
3: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:81:12:78 brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.1/30 brd 192.168.255.3 scope global noprefixroute bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe81:1278/64 scope link 
       valid_lft forever preferred_lft forever
4: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:81:12:78 brd ff:ff:ff:ff:ff:ff
5: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:de:1e:43 brd ff:ff:ff:ff:ff:ff
6: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:6d:07:3f brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.10/24 brd 192.168.56.255 scope global noprefixroute eth3
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe6d:73f/64 scope link 
       valid_lft forever preferred_lft forever
[root@inetRouter ~]# ping 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=1.04 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.723 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=1.25 ms
64 bytes from 192.168.255.2: icmp_seq=4 ttl=64 time=1.23 ms
64 bytes from 192.168.255.2: icmp_seq=5 ttl=64 time=0.948 ms

```
4. Не отменяя ping подключаемся к хосту centralRouter и выключаем там интерфейс eth1:
```
root@LinuxMint:/var/vlan# vagrant ssh centralRouter
Last login: Thu Jun 20 08:17:54 2024 from 192.168.56.1
[vagrant@centralRouter ~]$ sudo -i
[root@centralRouter ~]# ip link set down eth1
```
После данного действия ping не должен пропасть, так как трафик пойдёт по-другому порту.
```
[root@centralRouter ~]# ip link set up eth1
```
