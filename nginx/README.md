# Динамический веб


## Создадим файл .env с переменными необходимыми для базы данных, wordpress и python приложения в коталоге /project 

Содержимое файла
```
# Переменные которые будут использоваться для создания и подключения БД
DB_NAME=wordpress 
DB_ROOT_PASSWORD=dbpassword 
# Переменные необходимые python приложению
MYSITE_SECRET_KEY=put_your_django_app_secret_key_here
DEBUG=True
```
далее запускаем и подключаемся 

```
vagrant up
vagrant ssh
cd project
docker-compose ps
```

Вывод команды docker-compose ps

```
vagrant@DynamicWeb:~/project$ docker-compose ps
  Name                 Command               State                                                                  Ports                                                                
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
app         gunicorn --workers=2 --bin ...   Up                                                                                                                                          
database    docker-entrypoint.sh --def ...   Up      3306/tcp, 33060/tcp                                                                                                                 
nginx       nginx -g daemon off;             Up      80/tcp, 0.0.0.0:8081->8081/tcp,:::8081->8081/tcp, 0.0.0.0:8082->8082/tcp,:::8082->8082/tcp, 0.0.0.0:8083->8083/tcp,:::8083->8083/tcp
node        docker-entrypoint.sh node  ...   Up                                                                                                                                          
wordpress   docker-entrypoint.sh php-fpm     Up      9000/tcp    
```
Проверяем доступность сайтов 
![image](https://github.com/ookml/otus_dz/assets/21999102/487f154e-5611-42da-85d7-7efa5e1616d4)
![image](https://github.com/ookml/otus_dz/assets/21999102/419c00f0-02e4-4c1b-971d-d09448e04e93)
![image](https://github.com/ookml/otus_dz/assets/21999102/acf21f86-53eb-4a9f-bb22-b3885d745e19)



