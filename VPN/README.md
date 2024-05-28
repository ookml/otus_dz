# Домашнее задание VPN


## Описание домашнего задания

1. Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях
2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ
3. (*) Самостоятельно изучить и настроить ocserv, подключиться с хоста к ВМ

Итак у нас 3 папки, в каждой лежит Vagrantfile, все делалось по инструкции, отклонения минимальные. После сборки необходимо руками выполнить следующие манипуляции:

## TAP
Замерим скорость в туннеле в режиме TAP. На openvpn сервере запускаем iperf3 в режиме сервера
```
iperf3 -s &
```
На openvpn клиенте запускаем iperf3 в режиме клиента
```
iperf3 -c 10.10.10.1 -t 40 -i 5
```

```
[root@server ~]# iperf3 -s &
[1] 3943
[root@server ~]# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 56428
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 56430
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  34.1 MBytes   286 Mbits/sec                  
[  5]   1.00-2.00   sec  36.4 MBytes   305 Mbits/sec                  
[  5]   2.00-3.00   sec  36.6 MBytes   307 Mbits/sec                  
[  5]   3.00-4.00   sec  35.8 MBytes   301 Mbits/sec                  
[  5]   4.00-5.00   sec  36.3 MBytes   304 Mbits/sec                  
[  5]   5.00-6.00   sec  36.8 MBytes   308 Mbits/sec                  
[  5]   6.00-7.00   sec  37.0 MBytes   311 Mbits/sec                  
[  5]   7.00-8.00   sec  36.6 MBytes   307 Mbits/sec                  
[  5]   8.00-9.00   sec  37.6 MBytes   315 Mbits/sec                  
[  5]   9.00-10.00  sec  37.6 MBytes   316 Mbits/sec                  
[  5]  10.00-11.00  sec  37.6 MBytes   316 Mbits/sec                  
[  5]  11.00-12.00  sec  37.9 MBytes   318 Mbits/sec                  
[  5]  12.00-13.00  sec  37.7 MBytes   316 Mbits/sec                  
[  5]  13.00-14.00  sec  37.2 MBytes   312 Mbits/sec                  
[  5]  14.00-15.00  sec  39.1 MBytes   328 Mbits/sec                  
[  5]  15.00-16.00  sec  39.0 MBytes   327 Mbits/sec                  
[  5]  16.00-17.00  sec  39.2 MBytes   329 Mbits/sec                  
[  5]  17.00-18.00  sec  39.7 MBytes   333 Mbits/sec                  
[  5]  18.00-19.00  sec  40.0 MBytes   335 Mbits/sec                  
[  5]  19.00-20.00  sec  39.6 MBytes   332 Mbits/sec                  
[  5]  20.00-21.00  sec  39.7 MBytes   333 Mbits/sec                  
[  5]  21.00-22.00  sec  39.7 MBytes   333 Mbits/sec                  
[  5]  22.00-23.00  sec  39.2 MBytes   329 Mbits/sec                  
[  5]  23.00-24.00  sec  39.6 MBytes   332 Mbits/sec                  
[  5]  24.00-25.00  sec  39.3 MBytes   330 Mbits/sec                  
[  5]  25.00-26.00  sec  39.9 MBytes   335 Mbits/sec                  
[  5]  26.00-27.00  sec  40.0 MBytes   335 Mbits/sec                  
[  5]  27.00-28.00  sec  39.6 MBytes   332 Mbits/sec                  
[  5]  28.00-29.00  sec  40.3 MBytes   338 Mbits/sec                  
[  5]  29.00-30.00  sec  39.7 MBytes   333 Mbits/sec                  
[  5]  30.00-31.00  sec  39.4 MBytes   331 Mbits/sec                  
[  5]  31.00-32.00  sec  38.8 MBytes   326 Mbits/sec                  
[  5]  32.00-33.00  sec  38.7 MBytes   325 Mbits/sec                  
[  5]  33.00-34.00  sec  37.7 MBytes   316 Mbits/sec                  
[  5]  34.00-35.00  sec  38.3 MBytes   321 Mbits/sec                  
[  5]  35.00-36.00  sec  38.7 MBytes   325 Mbits/sec                  
[  5]  36.00-37.00  sec  39.6 MBytes   332 Mbits/sec                  
[  5]  37.00-38.00  sec  40.0 MBytes   336 Mbits/sec                  
[  5]  38.00-39.00  sec  39.5 MBytes   331 Mbits/sec                  
[  5]  39.00-40.00  sec  39.3 MBytes   330 Mbits/sec                  
[  5]  40.00-40.09  sec  2.75 MBytes   264 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.09  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.09  sec  1.51 GBytes   323 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 56432

```

```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 56434 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec   194 MBytes   326 Mbits/sec   21    511 KBytes       
[  4]   5.00-10.01  sec   197 MBytes   331 Mbits/sec   12    468 KBytes       
[  4]  10.01-15.00  sec   197 MBytes   331 Mbits/sec  128    608 KBytes       
[  4]  15.00-20.01  sec   196 MBytes   329 Mbits/sec    5    464 KBytes       
[  4]  20.01-25.00  sec   198 MBytes   333 Mbits/sec  165    378 KBytes       
[  4]  25.00-30.00  sec   199 MBytes   334 Mbits/sec  204    425 KBytes       
[  4]  30.00-35.01  sec   199 MBytes   333 Mbits/sec    6    601 KBytes       
^Z
[1]+  Stopped                 iperf3 -c 10.10.10.1 -t 40 -i 5
```

## TUN
Замерим скорость в туннеле в режиме TUN.

Выхлоп:

```
[root@server ~]# iperf3 -s &
[1] 3952
[root@server ~]# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 45316
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 45318
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec  33.1 MBytes   278 Mbits/sec                  
[  5]   1.00-2.00   sec  35.6 MBytes   299 Mbits/sec                  
[  5]   2.00-3.00   sec  36.0 MBytes   302 Mbits/sec                  
[  5]   3.00-4.00   sec  36.5 MBytes   306 Mbits/sec                  
[  5]   4.00-5.00   sec  36.8 MBytes   309 Mbits/sec                  
[  5]   5.00-6.00   sec  36.1 MBytes   303 Mbits/sec                  
[  5]   6.00-7.00   sec  36.5 MBytes   306 Mbits/sec                  
[  5]   7.00-8.00   sec  36.2 MBytes   304 Mbits/sec                  
[  5]   8.00-9.00   sec  36.1 MBytes   303 Mbits/sec                  
[  5]   9.00-10.00  sec  36.4 MBytes   306 Mbits/sec                  
[  5]  10.00-11.00  sec  36.3 MBytes   304 Mbits/sec                  
[  5]  11.00-12.00  sec  36.4 MBytes   306 Mbits/sec                  
[  5]  12.00-13.00  sec  36.7 MBytes   307 Mbits/sec                  
[  5]  13.00-14.00  sec  36.2 MBytes   304 Mbits/sec                  
[  5]  14.00-15.00  sec  37.2 MBytes   312 Mbits/sec                  
[  5]  15.00-16.00  sec  36.6 MBytes   307 Mbits/sec                  
[  5]  16.00-17.00  sec  36.5 MBytes   306 Mbits/sec                  
[  5]  17.00-18.00  sec  36.9 MBytes   309 Mbits/sec                  
[  5]  18.00-19.00  sec  36.5 MBytes   306 Mbits/sec                  
[  5]  19.00-20.00  sec  36.2 MBytes   304 Mbits/sec                  
[  5]  20.00-21.00  sec  37.5 MBytes   314 Mbits/sec                  
[  5]  21.00-22.00  sec  35.6 MBytes   298 Mbits/sec                  
[  5]  22.00-23.00  sec  36.5 MBytes   306 Mbits/sec                  
[  5]  23.00-24.00  sec  36.5 MBytes   306 Mbits/sec                  
[  5]  24.00-25.00  sec  36.8 MBytes   309 Mbits/sec                  
[  5]  25.00-26.00  sec  35.9 MBytes   301 Mbits/sec                  
[  5]  26.00-27.00  sec  37.2 MBytes   312 Mbits/sec                  
[  5]  27.00-28.00  sec  35.2 MBytes   295 Mbits/sec                  
[  5]  28.00-29.00  sec  36.4 MBytes   305 Mbits/sec                  
[  5]  29.00-30.00  sec  36.2 MBytes   303 Mbits/sec                  
[  5]  30.00-31.00  sec  37.1 MBytes   311 Mbits/sec                  
[  5]  31.00-32.00  sec  37.0 MBytes   311 Mbits/sec                  
[  5]  32.00-33.00  sec  36.3 MBytes   305 Mbits/sec                  
[  5]  33.00-34.00  sec  36.3 MBytes   305 Mbits/sec                  
[  5]  34.00-35.00  sec  36.7 MBytes   308 Mbits/sec                  
[  5]  35.00-36.00  sec  36.3 MBytes   305 Mbits/sec                  
[  5]  36.00-37.00  sec  37.0 MBytes   311 Mbits/sec                  
[  5]  37.00-38.00  sec  36.7 MBytes   308 Mbits/sec                  
[  5]  38.00-39.00  sec  37.0 MBytes   311 Mbits/sec                  
[  5]  39.00-40.00  sec  36.1 MBytes   303 Mbits/sec                  
[  5]  40.00-40.10  sec  3.01 MBytes   247 Mbits/sec                  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-40.10  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-40.10  sec  1.42 GBytes   305 Mbits/sec                  receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 45318 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.01   sec   184 MBytes   307 Mbits/sec  339    431 KBytes       
[  4]   5.01-10.00  sec   181 MBytes   304 Mbits/sec   76    454 KBytes       
[  4]  10.00-15.00  sec   184 MBytes   308 Mbits/sec  177    565 KBytes       
[  4]  15.00-20.00  sec   182 MBytes   306 Mbits/sec   67    578 KBytes       
[  4]  20.00-25.00  sec   182 MBytes   306 Mbits/sec    0    742 KBytes       
[  4]  25.00-30.00  sec   181 MBytes   304 Mbits/sec  279    449 KBytes       
[  4]  30.00-35.00  sec   183 MBytes   308 Mbits/sec    0    679 KBytes       
[  4]  35.00-40.00  sec   183 MBytes   308 Mbits/sec    0    848 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-40.00  sec  1.43 GBytes   306 Mbits/sec  938             sender
[  4]   0.00-40.00  sec  1.42 GBytes   306 Mbits/sec                  receiver

iperf Done.
```
## RAS
С режимом RAS все немного сложнее, на хостовой машине выполняем следующие команды (пароль: vagrant):
```
ssh-keyscan -H 192.168.10.10 >> ~/.ssh/known_hosts
scp root@192.168.10.10:/etc/openvpn/pki/ca.crt ./
scp root@192.168.10.10:/etc/openvpn/pki/issued/client.crt ./
scp root@192.168.10.10:/etc/openvpn/pki/private/client.key ./
sudo openvpn  --config client.conf
```
Теперь проверяем:
```
root@LinuxMint:/var/Administrator-Linux-Professional/hometasks/31_vpn/ras# ip r
default via 192.168.88.1 dev enp3s0 proto dhcp metric 100 
10.10.10.1 via 10.10.10.5 dev tun0 
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6 
169.254.0.0/16 dev enp3s0 scope link metric 1000 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
192.168.10.0/24 dev vboxnet6 proto kernel scope link src 192.168.10.1 
192.168.50.0/24 dev vboxnet5 proto kernel scope link src 192.168.50.1 linkdown 
192.168.56.0/24 dev vboxnet1 proto kernel scope link src 192.168.56.1 linkdown 
192.168.88.0/24 dev enp3s0 proto kernel scope link src 192.168.88.66 metric 100
root@LinuxMint:/var/Administrator-Linux-Professional/hometasks/31_vpn/ras# ping  -c 4 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.809 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.771 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.797 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.758 ms

--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3056ms
rtt min/avg/max/mdev = 0.758/0.783/0.809/0.020 ms
```
Видим что поднялся **10.10.10.1 via 10.10.10.5 dev tun0 ** и пинги идут.

