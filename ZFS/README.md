# Команда выводит информацию о пулах
[root@zfs ~]# zpool list

NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
# Команда показывает методы сжатия
[root@zfs ~]# zfs get all | grep compression

otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
# Проверяем скачались ли все файлы в указанные пулы из скрипта
[root@zfs ~]# ls -l /otus*

/otus1:
total 22067
-rw-r--r--. 1 root root 41016061 Feb  2 08:53 pg2600.converter.log

/otus2:
total 17994
-rw-r--r--. 1 root root 41016061 Feb  2 08:53 pg2600.converter.log

/otus3:
total 10959
-rw-r--r--. 1 root root 41016061 Feb  2 08:53 pg2600.converter.log

/otus4:
total 40091
-rw-r--r--. 1 root root 41016061 Feb  2 08:53 pg2600.converter.log
# Проверяем и видем что лучший метод зжатия gzip-9
[root@zfs ~]# zfs list

NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M   330M     21.6M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.3M   313M     39.2M  /otus4
# Убедились что самый лучший способ сжатия gzip-9
[root@zfs ~]# zfs get all | grep compressratio | grep -v ref

otus1  compressratio         1.80x                  -
otus2  compressratio         2.21x                  -
otus3  compressratio         3.63x                  -
otus4  compressratio         1.00x                  -
# Скаиваем архив и разархивируем его 
[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
--2024-02-05 08:34:04--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download

[root@zfs ~]# tar -xzvf archive.tar.gz 
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
# Проверяем возможность импорта в данный коталог пула (Показывает нам имя пулла тип RAID и каталог)
[root@zfs ~]# zpool import -d zpoolexport/

   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE

# Импортируем 
[root@zfs ~]# zpool import -d zpoolexport/ otus

# Определить настройки 

[root@zfs ~]# zfs get available otus   
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
[root@zfs ~]# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
[root@zfs ~]# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
[root@zfs ~]# zfs get compression otus
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
[root@zfs ~]# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

# Восстановление из скаченного снапшета 
[root@zfs ~]# zfs receive otus/test2 < otus_task2.file
[root@zfs ~]# find /otus/test2 -name "secret_message"
/otus/test2/task1/file_mess/secret_message
[root@zfs ~]# cat /otus/test2/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/






  

