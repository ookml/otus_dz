 # Попасть в систему без пароля несколькими способами

## Способ 1. init=/bin/sh

В конце строки начинаеться с linux16 добавляем init=/bin/sh и нажимаем сtrl-x для
загрузки в систему

● В целом на этом все, Вы попали в систему. Но есть один нюанс. Рутовая файловая
система при этом монтируеться в режиме Read-Only. Если вы хотите перемонтировать ее в
режим Read-Write можно воспользоватесь командой:

mount -o remount,rw /

## Способ 2. rd.break

● В конце строки начинающейся с linux16 добавлāем rd.break и нажимаем сtrl-x для
загрузки в систему

● Попадаем в emergency mode. Нlesson10аша корневая файловая система смонтирована (опять же
в режиме Read-Only, но мы не в ней. Далее будет пример как попасть в нее и поменять
пароль администратора:

    [root@lesson10 ~]# mount -o remount,rw /sysroot
    [root@lesson10 ~]# chroot /sysroot
    [root@lesson10 ~]# passwd root
    [root@lesson10 ~]# touch /.autorelabel

● После чего можно перезагружаться и заходить в систему с новым паролем. Полезно
когда вы потеряли или вообще не имели пароль администратор.

## Способ 3. rw init=/sysroot/bin/sh

● В строке начинающейся с linux16 заменяем ro на rw init=/sysroot/bin/sh и нажимаем сtrl-x
для загрузки в систему

● В целом то же самое что и в прошлом примере, но файловаā система сразу
смонтирована в режим Read-Write

● В прошлых примерах тоже можно заменить ro на rw

# Установить систему с LVM, после чего переименовать VG

● Первым делом посмотрим текущее состояние системы:

   
    [root@lesson10 ~]# vgs
    VG         #PV #LV #SN Attr   VSize   VFree
    VolGroup00   1   2   0 wz--n- <38.97g    0 
    
 Приступим к переименованию:
   
    [root@lesson10 ~]# lsblk
    NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                       8:0    0   40G  0 disk 
    |-sda1                    8:1    0    1M  0 part 
    |-sda2                    8:2    0    1G  0 part /boot
    `-sda3                    8:3    0   39G  0 part 
      |-VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
      `-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
    sdb                       8:16   0    1G  0 disk 

    [root@lesson10 ~]# vgrename VolGroup00 OtusRoot
    Volume group "VolGroup00" successfully renamed to "OtusRoot"

 После переименовывания правим след. конф. файлы /etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg;

 Пересоздаем initrd image, чтобы он знал новое название Volume Group
    
    [root@lesson10 ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
    *** Creating image file ***
    *** Creating image file done ***
    *** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
Перезагружаемся и видим 

    [root@lesson10 ~]# lsblk
    NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                     8:0    0   40G  0 disk 
    |-sda1                  8:1    0    1M  0 part 
    |-sda2                  8:2    0    1G  0 part /boot
    `-sda3                  8:3    0   39G  0 part 
      |-OtusRoot-LogVol00 253:0    0 37.5G  0 lvm  /
      `-OtusRoot-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
    sdb                     8:16   0    1G  0 disk 
    [root@lesson10 ~]# vgs
    VG       #PV #LV #SN Attr   VSize   VFree
    OtusRoot   1   2   0 wz--n- <38.97g    0 
    [root@lesson10 ~]# ls -l /dev/OtusRoot/
    total 0
    lrwxrwxrwx. 1 root root 7 Feb 13 09:48 LogVol00 -> ../dm-0
    lrwxrwxrwx. 1 root root 7 Feb 13 09:48 LogVol01 -> ../dm-1


 # Добавить модуль в initrd

 Скрипты модулей хранятся в каталоге /usr/lib/dracut/modules.d/. Для того чтобы
 добавить свой модуль создаем там папку с именем 01test:

    [root@lesson10 ~]# mkdir /usr/lib/dracut/modules.d/01test

В ней создадим два файла и поместем содержимое со скриптов в репозитории:

    [root@lesson10 ~]# nano /usr/lib/dracut/modules.d/01test/module-setup.sh
    [root@lesson10 ~]# nano /usr/lib/dracut/modules.d/01test/test.sh
    [root@lesson10 ~]# ls -l /usr/lib/dracut/modules.d/01test/
    total 8/01test/
    -rw-r--r--. 1 root root 126 Feb 13 10:38 module-setup.sh
    -rw-r--r--. 1 root root 332 Feb 13 10:39 test.sh

 Пересобираем образ initrd
 
    [root@lesson10 ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
    [root@lesson10 ~]# dracut -f -v

 Проверяем что все работает

    root@lesson10 ~]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
    test

 удаляем rghb и quiet в /boot/grub2/grub.cfg

 В итоге при загрузке будет пауза на 10 секунд и вý увидите пингвина в вýводе
терминала


