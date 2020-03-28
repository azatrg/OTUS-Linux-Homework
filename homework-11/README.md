# Docker

## Домашнее задание

1. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
Определите разницу между контейнером и образом
Вывод опишите в домашнем задании.
Ответьте на вопрос: Можно ли в контейнере собрать ядро?
Собранный образ необходимо запушить в docker hub и дать ссылку на ваш
репозиторий.

* Создайте кастомные образы nginx и php, объедините их в docker-compose.
После запуска nginx должен показывать php info.
Все собранные образы должны быть в docker hub

## Решение.

#### Образ Nginx

1. Подготовил [Dockerfile](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-11/Dockerfile_nginx)
2. Для сборки в папке с Dockerfile выполню команду
```
docker build -t nginx:v0.3 .
```
3. Залью образ в dockerhub
```
docker tag nginx:v0.3 azatrg/nginx:v0.3
docker push azatrg/nginx:v0.3
```
4. Проверка образа
```
docker run -d -p 8081:80 azatrg/nginx:v0.3
curl 127.0.0.1:8081
```

#### Образ Php-fpm

1. Подготовил [Dockerfile](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-11/Dockerfile_php-fpm)

2. Сборка аналогично образу с nginx, но имя образа будет php-fpm:v0.3 


#### docker compose nginx+php.

1. Подготовил файл [docker-compose.yml](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-11/docker-compose.yml)

2. Перед запуском проверить что в текущей папке присутствуют файлы

```
├── default_php.conf		# конфиг nginx
├── docker-compose.yml		# файл для docker-compose
├── index.php			# заглавная страница с php info
└── www.conf			# Конфиг php-fpm

```
3. Выполнить команду
```
docker-compose up -d
```

4. Для проверки зайти браузером на 127.0.0.1:8080 - должна открыться страница с php info


