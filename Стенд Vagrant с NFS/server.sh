   yum install nfs-utils
# Включаем Firewall
     systemctl enable firewalld --now 
# Разрешаем доступ к NFS
     firewall-cmd --add-service="nfs3" \
     --add-service="rpc-bind" \
     --add-service="mountd" \
     --permanent 
     firewall-cmd --reload

# Включаем сервер NFS
     systemctl enable nfs --now 
# Cоздаём и настраиваем директорию
   mkdir -p /srv/share/upload 
   chown -R nfsnobody:nfsnobody /srv/share 
   chmod 0777 /srv/share/upload 

# Помещаем в файл exports
   echo "/srv/share 172.16.0.25/32(rw,sync,root_squash)" >> /etc/exports
# Экспортируем ранее созданную директорию
   exportfs -r
