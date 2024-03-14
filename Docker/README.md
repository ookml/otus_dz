## Цель домашнего задания
## Разобраться с основами docker, с образом, эко системой docker в целом;

1. Установите Docker на хост машину

Настройте aptрепозиторий Docker
 ```
   # Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
   ```
Установка Docker
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
2. Установите Docker Compose - как плагин, или как отдельное приложение

```
oem@LinuxMint:~$ sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 15.4M  100 15.4M    0     0  5523k      0  0:00:02  0:00:02 --:--:-- 8925k
oem@LinuxMint:~$ sudo chmod +x /usr/local/bin/docker-compose
oem@LinuxMint:~$ docker-compose --version
docker-compose version 1.24.1, build 4667896b
```
3. Создайте свой кастомный образ nginx на базе alpine
```
oem@LinuxMint:/var/docker$ ls
Dockerfile  index.html
oem@LinuxMint:/var/docker$ sudo docker build -t otusbox/myimages:nginx .
[+] Building 54.5s (10/10) FINISHED                                                                                                                                                                                          docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                                                                   0.0s
 => => transferring dockerfile: 950B                                                                                                                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/alpine:latest                                                                                                                                                                       1.8s
 => [internal] load .dockerignore                                                                                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                                                                                        0.0s
 => [1/5] FROM docker.io/library/alpine:latest@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b                                                                                                                 0.9s
 => => resolve docker.io/library/alpine:latest@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b                                                                                                                 0.0s
 => => sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8 3.41MB / 3.41MB                                                                                                                                         0.7s
 => => sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b 1.64kB / 1.64kB                                                                                                                                         0.0s
 => => sha256:6457d53fb065d6f250e1504b9bc42d5b6c65941d57532c072d929dd0628977d0 528B / 528B                                                                                                                                             0.0s
 => => sha256:05455a08881ea9cf0e752bc48e61bbd71a34c029bb13df01e40e3e70e0d007bd 1.47kB / 1.47kB                                                                                                                                         0.0s
 => => extracting sha256:4abcf20661432fb2d719aaf90656f55c287f8ca915dc1c92ec14ff61e67fbaf8                                                                                                                                              0.1s
 => [internal] load build context                                                                                                                                                                                                      0.0s
 => => transferring context: 66B                                                                                                                                                                                                       0.0s
 => [2/5] RUN apk --update --no-cache add build-base         openssl-dev         pcre-dev         zlib-dev         wget                                                                                                               25.8s
 => [3/5] RUN mkdir -p /tmp/src &&     cd /tmp/src &&     wget http://nginx.org/download/nginx-1.24.0.tar.gz &&     tar zxf nginx-1.24.0.tar.gz &&     cd nginx-1.24.0 &&     ./configure --sbin-path=/usr/bin/nginx         --conf-  24.8s 
 => [4/5] RUN ln -sf /dev/stdout /var/log/nginx/access.log &&     ln -sf /dev/stderr /var/log/nginx/error.log                                                                                                                          0.4s 
 => [5/5] COPY index.html /usr/local/nginx/html/index.html                                                                                                                                                                             0.0s 
 => exporting to image                                                                                                                                                                                                                 0.8s 
 => => exporting layers                                                                                                                                                                                                                0.7s 
 => => writing image sha256:0a188e6a6e4522ac1467355dddbc5c5d8511b6506ae6090314369fa0623223f7                                                                                                                                           0.0s 
 => => naming to docker.io/otusbox/myimages:nginx        
```
```
oem@LinuxMint:/var/docker$ docker run -d -p 1234:80 otusbox/myimages:nginx
420cb46ce5e05fba66e8a34b22214c96e3a1d98d115d2c5da176184574e408fd
``` 
```
oem@LinuxMint:/var/docker$ docker images
REPOSITORY         TAG       IMAGE ID       CREATED         SIZE
otusbox/myimages   nginx     0a188e6a6e45   8 minutes ago   242MB
oem@LinuxMint:/var/docker$ docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS          PORTS                                            NAMES
420cb46ce5e0   otusbox/myimages:nginx   "nginx -g 'daemon of…"   27 seconds ago   Up 26 seconds   443/tcp, 0.0.0.0:1234->80/tcp, :::1234->80/tcp   elated_ramanujan
```

4. Определите разницу между контейнером и образом
   
Образы могут существовать без контейнеров, тогда как для существования контейнеров необходимо запустить образ. Поэтому контейнеры зависят от изображений и используют их для создания среды выполнения и запуска приложения.
