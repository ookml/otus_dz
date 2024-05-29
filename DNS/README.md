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

Нужно обратить внимание, на каком адресе и порту работают наши DNS-сервера. 

Для этого подключаемся на хост ns01 и проверяем командой ss -tulpn

```
root@LinuxMint:/var/vagrant-bind/provisioning# vagrant ssh ns01
[vagrant@ns01 ~]$ ss -tulpn
Netid  State      Recv-Q Send-Q                                                                      Local Address:Port                                                                                     Peer Address:Port              
udp    UNCONN     0      0                                                                           192.168.50.10:53                                                                                                  *:*                  
udp    UNCONN     0      0                                                                               127.0.0.1:323                                                                                                 *:*                  
udp    UNCONN     0      0                                                                                       *:68                                                                                                  *:*                  
udp    UNCONN     0      0                                                                                       *:111                                                                                                 *:*                  
udp    UNCONN     0      0                                                                                       *:927                                                                                                 *:*                  
udp    UNCONN     0      0                                                                                   [::1]:53                                                                                               [::]:*                  
udp    UNCONN     0      0                                                                                   [::1]:323                                                                                              [::]:*                  
udp    UNCONN     0      0                                                                                    [::]:111                                                                                              [::]:*                  
udp    UNCONN     0      0                                                                                    [::]:927                                                                                              [::]:*                  
tcp    LISTEN     0      10                                                                          192.168.50.10:53                                                                                                  *:*                  
tcp    LISTEN     0      128                                                                                     *:22                                                                                                  *:*                  
tcp    LISTEN     0      128                                                                         192.168.50.10:953                                                                                                 *:*                  
tcp    LISTEN     0      100                                                                             127.0.0.1:25                                                                                                  *:*                  
tcp    LISTEN     0      128                                                                                     *:111                                                                                                 *:*                  
tcp    LISTEN     0      10                                                                                  [::1]:53                                                                                               [::]:*                  
tcp    LISTEN     0      128                                                                                  [::]:22                                                                                               [::]:*                  
tcp    LISTEN     0      100                                                                                 [::1]:25                                                                                               [::]:*                  
tcp    LISTEN     0      128                                                                                  [::]:111                                                                                              [::]:*  
```

проверяем настройки зон 

```
[root@ns01 ~]# cat /etc/named/named.ddns.lab 
$TTL 3600
$ORIGIN ddns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
```

провеяем с клиента зоны
```
[vagrant@client ~]$ dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29513
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.                  IN      A

;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.50.15

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns01.dns.lab.
dns.lab.                3600    IN      NS      ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Wed May 29 12:17:29 UTC 2024
;; MSG SIZE  rcvd: 127

```
```
[vagrant@client ~]$  dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45779
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.                  IN      A

;; ANSWER SECTION:
web2.dns.lab.           3600    IN      A       192.168.50.16

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns01.dns.lab.
dns.lab.                3600    IN      NS      ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Wed May 29 12:20:10 UTC 2024
;; MSG SIZE  rcvd: 127
```
В примерах мы обратились к разным DNS-серверам с разными запросами


Проверка на client2: 

```
[vagrant@client2 ~]$ ping www.newdns.lab
PING www.newdns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.021 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.061 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.064 ms

[vagrant@client2 ~]$ ping web1.dns.lab  
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=1.13 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=0.743 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=3 ttl=64 time=0.604 ms

[vagrant@client2 ~]$ ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.044 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.070 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.067 ms
```
