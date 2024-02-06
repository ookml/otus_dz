                                                                              #Стенд Vagrant с NFS
      #Настройка сервера                                                                        
1. ## Доустановка компонентов
---bash
   yum install nfs-utils
   ---
3. ## Включаем Firewall
     systemctl enable firewalld --now 
4. ## Разрешаем доступ к NFS
     firewall-cmd --add-service="nfs3" \
     --add-service="rpc-bind" \
     --add-service="mountd" \
     --permanent 
     firewall-cmd --reload

5. ## Включаем сервер NFS
     systemctl enable nfs --now 
6. ## Cоздаём и настраиваем директорию
   mkdir -p /srv/share/upload 
   chown -R nfsnobody:nfsnobody /srv/share 
   chmod 0777 /srv/share/upload 

7. ## Помещаем в файл exports
   cat << EOF > /etc/exports 
   /srv/share 172.16.0.20/32(rw,sync,root_squash)
   EOF
8. ## Экспортируем ранее созданную директорию
[root@nfss ~]# exportfs -r
[root@nfss ~]# exportfs -s
/srv/share  172.16.0.20/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
8. 
