# Научиться создавать пользователей и добавлять им ограничения

1. Запретить всем пользователям кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

* дать конкретному пользователю права работать с докером и возможность перезапускать докер сервис

## Запустить vagrant up

   После загрузки VM, нужно проверить, что созданные пользователи в vagrantfile могут подключаться по SSH к нашей ВМ. Для этого пытаемся подключиться с хостовой машины: 
ssh otus@192.168.57.10

Далее вводим наш созданный пароль. 

```
root@LinuxMint:~# ssh otus@192.168.57.10
otus@192.168.57.10's password: 
Last login: Thu Apr  4 09:51:16 2024 from 192.168.57.1
[otus@pam ~]$ whoami
otus
[otus@pam ~]$ exit
logout
Connection to 192.168.57.10 closed.
```
Далее настроим правило, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:

## Проверим, что пользователи root, vagrant и otusadm есть в группе admin:
```
[root@pam ~]# cat /etc/group | grep admin
printadmin:x:997:
admin:x:1003:otusadm,root,vagrant
```
## Создадим файл-скрипт /usr/local/bin/login.sh
```
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi
```
## Добавим права на исполнение файла: chmod +x /usr/local/bin/login.sh

## Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:
```
vim /etc/pam.d/sshd 


#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
auth required pam_exec.so debug /usr/local/bin/login.sh
account    required     dad
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
```
