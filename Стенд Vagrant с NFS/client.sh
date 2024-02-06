# Доустановка компонентов
    yum install nfs-utils 

# Включаем Firewall
    systemctl enable firewalld --now 

# добавляем строку и перезагружаем 
    echo "172.16.0.20:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

    systemctl daemon-reload 
    systemctl restart remote-fs.target 
