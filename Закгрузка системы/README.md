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
   
    [root@lesson10 ~]# vgrename VolGroup00 OtusRoot
    Volume group "VolGroup00" successfully renamed to "OtusRoot"

Пересоздаем initrd image, чтобý он знал новое название Volume Group
    
    [root@lesson10 ~]# mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)

    

    



