# Docker

### Установка Docker.

1. Официальная инструкция для Centos доступна по [ссылке](https://docs.docker.com/install/linux/docker-ce/centos/)
2. Подключаем репо 
```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 && \
  sudo yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```
3. Установка docker
```
sudo yum install -y docker-ce docker-ce-cli containerd.io
```
4. Запускаю службу и проверяю работоспособность.
```
sudo systemctl enable docker
sudo systemctl start docker
sudo docker run hello-world
```
5. Для запуска контейнеров от обычного пользователя добавляю его в группу docker
```
sudo usermod -aG docker $(whoami)
```

6. Docker-compose ставиться отдельно путем копирования из репозитория на github.

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```


### Запуск контейнеров

Для запуска и подключения к контейнеру надо выполнить команду
```
docker run -it alpine:latest
```
Для отключения без остановки можно использовать горячие клавиши ctrl+P ctrl+q

Для запуска в бэкграунде надо добавить ключ -d
```
docker run -d alpine:latest
```
или если первый вариант не сработал
```
docker run -d alpine tail -f /dev/null
```
Для входа в shell контейнера 
```
docker exec -it <container id> /bin/sh
```

### Dockerfile

#### Nginx

Dockerfile это файл с именем Dockerfile в текущей директории в котором описывается как собирать образ. В примере ниже я буду собирать обрз с nginx из легковесного alpine
1. Установка nginx
```
apk update
apk --no-cache add nginx
```
2. создам необходимые папки
```
mkdir /run/nginx
mkdir -p /usr/share/nginx/html
chown -R nginx:nginx /usr/share/nginx/html/
```
3. Запуск\проверка конфига\перезагрузка конфига
```
nginx
nginx -t
nginx -s reload
```
4. Скопировать конфиги /etc/nginx/conf.d/default.conf и файлы /usr/share/nginx/html/index.html
5. Добавить подключение к php

#### Php

1. Установлю php 7 и php-fpm
```
apk update
apk --no-cache add php7 php7-fpm
```
*1* Возможно надо еще добавить эту команду для того чтобы образ был еще меньше
```
rm -rf /var/cache/apk/*
```
2. поправить конфиг php-fpm который лежит - ls /etc/php7/php-fpm.conf и /etc/php7/php-fpm.d/www.conf 

```
listen = 9000
```

#### Создание Image и загрузка в dockerhub

1. В папке с Dockerfile выполнить 
```
docker build -t aznginx:v0.2 .
```
запуск контейнера
```
docker run -d -p 7777:80 aznginx:v0.2
```

2. Зарегистрироваться на сайте [https://hub.docker.com/](https://hub.docker.com/) и создать репозиторий.

3. Залогиниться в docker hub из cli

```
docker login
```
Загрузить образ в dockerhub
```
docker tag aznginx:v0.2 azatrg/otusnginx:v0.1
docker push azatrg/otusnginx:v0.
```

#### docker compose nginx+php.

1. Подготовка конфигов.
 Внесу следующие изменения


2. Файл с описанием називается docker-compose.yml создам его.
3. Файл должен быть примерно следующего содержания

```

```
4. Почему-то писало ошибку file not found. как я понял php-fpm не мог прочитать. Помогло добавление volume с этим файлом также в  контенер с php-fpm. Насколько корректно так делать?
