# Vagrant-стенд c DNS

## Описание домашнего задания

1. взять стенд https://github.com/erlong15/vagrant-bind 
* добавить еще один сервер client2
* завести в зоне dns.lab имена:
   * web1 - смотрит на клиент1
   * web2  смотрит на клиент2
* завести еще одну зону newdns.lab
* завести в ней запись
   * www - смотрит на обоих клиентов

2. настроить split-dns
* клиент1 - видит обе зоны, но в зоне dns.lab только web1
* клиент2 видит только dns.lab

1. Работа со стендом и настройка DNS

```
➜  git clone https://github.com/erlong15/vagrant-bind.git
➜  cd vagrant-bind 
➜  vagrant-bind  ls -l 
total 12
drwxrwxr-x 2 alex alex 4096 мар 22 18:03 provisioning
-rw-rw-r-- 1 alex alex  414 мар 22 18:03 README.md
-rw-rw-r-- 1 alex alex  820 мар 22 18:03 Vagrantfile
```
Мы увидем файл Vagrantfile. Откроем его в любом, удобном для вас текстовом редакторе и добавим необходимую ВМ:
```
  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    client2.vm.hostname = "client2"
```
После внесения изменений, можно попробовать развернуть наши ВМ, для этого нужно воспользоваться командой: vagrant up 

После того, как у нас получилось добавить виртуальную машину client2, давайте подробнее разберем остальные файлы. Для этого перейдём в каталог provisoning: cd provisioning

* Рассмотрим требуемые нам файлы:
playbook.yml — это Ansible-playbook, в котором содержатся инструкции по настройке нашего стенда
* client-motd — файл, содержимое которого будет появляться перед пользователем, который подключился по SSH
* named.ddns.lab и named.dns.lab — файлы описания зон ddns.lab и dns.lab соответсвенно
* master-named.conf и slave-named.conf — конфигурационные файлы, в которых хранятся настройки DNS-сервера
* client-resolv.conf и servers-resolv.conf — файлы, в которых содержатся IP-адреса DNS-серверов

