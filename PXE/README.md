# Домашние задание Vagrant-стенд c PXE

## Цель домашнего задания
Отработать навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки

Описание домашнего задания

1. Следуя шагам из документа https://docs.centos.org/en-US/8-docs/advanced-install/assembly_preparing-for-a-network-install  установить и настроить загрузку по сети для дистрибутива CentOS 8.
В качестве шаблона воспользуйтесь репозиторием https://github.com/nixuser/virtlab/tree/main/centos_pxe 
2. Поменять установку из репозитория NFS на установку из репозитория HTTP.
3. Настроить автоматическую установку для созданного kickstart файла (*) Файл загружается по HTTP.

## Vagrantfile

```
# -*- mode: ruby -*-
# vi: set ft=ruby :
# export VAGRANT_EXPERIMENTAL="disks"

Vagrant.configure("2") do |config|

config.vm.define "pxeserver" do |server|
  server.vm.box = 'bento/centos-8.4'
  server.vm.disk :disk, size: "15GB", name: "extra_storage1"

  server.vm.host_name = 'pxeserver'
  server.vm.network :private_network, 
                     ip: "10.0.0.20", 
                     virtualbox__intnet: 'pxenet'
  server.vm.network :private_network, ip: "192.168.56.10", adapter: 3

  # server.vm.network "forwarded_port", guest: 80, host: 8081

  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # ENABLE to setup PXE
#  server.vm.provision "shell",
#    name: "Setup PXE server",
#    path: "setup_pxe.sh"
  end


# config used from this
# https://github.com/eoli3n/vagrant-pxe/blob/master/client/Vagrantfile
  config.vm.define "pxeclient" do |pxeclient|
    pxeclient.vm.box = 'bento/centos-8.4'
    pxeclient.vm.host_name = 'pxeclient'
    pxeclient.vm.network :private_network, ip: "10.0.0.21"
    pxeclient.vm.provider :virtualbox do |vb|
      vb.memory = "2048"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize [
          'modifyvm', :id,
          '--nic1', 'intnet',
          '--intnet1', 'pxenet',
          '--nic2', 'nat',
          '--boot1', 'net',
          '--boot2', 'none',
          '--boot3', 'none',
          '--boot4', 'none'
        ]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
      # ENABLE to fix memory issues
    # endvirt  
  end

end
```
Данный Vagrantfile развернет нам 2 хоста: pxeserver и pxeclient:

```
root@o0kml-pc:/home/o0kml/dhcp_pxe# vagrant status
Current machine states:

pxeserver                 running (virtualbox)
pxeclient                 running (virtualbox)

```
Теперь мы приступаем к настройке PXE-сервера.
Для настроки хоста с помощью Ansible создадим необходимые файлы и структуру директорий в отдельной папке ansible:

Создадим конфигурационный файл ansible.cfg, который описывает базовые настройки для работы Ansible:

```
root@o0kml-pc:/home/o0kml/dhcp_pxe/ansible# cat ansible.cfg 
[defaults]
#Отключение проверки ключа хоста
host_key_checking = false
#Указываем имя файла инвентаризации
inventory = hosts
#Отключаем игнорирование предупреждений
command_warnings= false
#remote_user = vagrant
#retry_files_enabled = False
```
Создадим файл инвентаризации hosts
```
root@o0kml-pc:/home/o0kml/dhcp_pxe/ansible# cat hosts 
[servers]
pxeserver ansible_host=192.168.56.10 ansible_user=vagrant ansible_ssh_private_key_file=.vagrant/machines/pxeserver/virtualbox/private_key
```
Создадим файл playbook.yml — основной файл, в котором содержатся инструкции (модули) по настройке для Ansible:
```
root@o0kml-pc:/home/o0kml/dhcp_pxe/ansible# cat playbook.yml 
---
- name: CentOS_PXE | Set up PXE Server
  #Указываем имя хоста или группу, которые будем настраивать
  hosts: pxeserver
  #Параметр выполнения модулей от root-пользователя
  become: true

  roles:
    - { role: dhcp_pxe, when: ansible_system == 'Linux' }
```
Создадим директорий roles и структуру директорий dhcp_pxe:
```
root@o0kml-pc:/home/o0kml/dhcp_pxe/ansible# mkdir ./roles && cd ./roles
root@o0kml-pc:/home/o0kml/dhcp_pxe/ansible/roles#  ansible-galaxy init dhcp_pxe
- Role dhcp_pxe was created successfully
```
## Настройка Web-сервера

Для того, чтобы отдавать файлы по HTTP нам потребуется настроенный веб-сервер.

Процесс настройки вручную: 
Так как у CentOS 8 закончилась поддержка, для установки пакетов нам потребуется поменять репозиторий. Сделать это можно с помощью следующих команд:

```
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
```
## 1. Устанавливаем Web-сервер Apache:
```
yum install httpd
```
## 2. Далее скачиваем образ CentOS 8.4.2150:
```
wget https://mirror.sale-dedic.com/centos/8.4.2105/isos/x86_64/CentOS-8.4.2105-x86_64-dvd1.iso
```
## 3. Монтируем данный образ:

```
mount -t iso9660 CentOS-8.4.2105-x86_64-dvd1.iso /mnt -o loop,ro
```
## 4. Создаём каталог /iso и копируем в него содержимое данного каталога:
```
mkdir /iso
cp -r /mnt/* /iso
```
## 5. Ставим права 755 на каталог /iso:

```
chmod -R 755 /iso
```
6. Настраиваем доступ по HTTP для файлов из каталога /iso:
● Создаем конфигурационный файл:
```
vi /etc/httpd/conf.d/pxeboot.conf
```
● Добавляем следующее содержимое в файл:
```
Alias /centos8 /iso
#Указываем адрес директории /iso
<Directory /iso>
    Options Indexes FollowSymLinks
    #Разрешаем подключения со всех ip-адресов
    Require all granted
</Directory>
```
● Перезапускаем веб-сервер:
```
systemctl restart httpd
```
● Добавляем его в автозагрузку:
```
systemctl enable httpd
```
7. Проверяем, что веб-сервер работает и каталог /iso доступен по сети:
● С нашего компьютера сначала подключаемся к тестовой странице Apache:
