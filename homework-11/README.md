# Docker

## Домашнее задание

1. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
Определите разницу между контейнером и образом
Вывод опишите в домашнем задании.
Ответьте на вопрос: Можно ли в контейнере собрать ядро?
Собранный образ необходимо запушить в docker hub и дать ссылку на ваш
репозиторий.

[Репозиторий с образом](https://hub.docker.com/repository/docker/azatrg/nginx)

Проверка образа
```
docker run -d -p 8081:80 azatrg/nginx:v0.3
curl 127.0.0.1:8081
```

**Ответы на вопросы**

1. Определите разницу между контейнером и образом.

Образ - это что-то вроде шаблона из которого запускатся контейнер. Можно использовать готовые образы или создавать свои на основе существующих. 
Контейнер это запущенный образ. При запуске можно задать настройки сети, портов, имени и внести некоторые изменения в файловую систему образа(так называемый верхний слой, доступный для записи).

2. Можно ли в контейнере собрать ядро. 

Смотря какой runtime для контейнеров используется. В Docker нет. Docker использует ядро хостовой системы. Docker не виртуальная машина. Это приложение и его зависимости упакованные в окружение. Если все-таки по какой-либо причине надо запустить собрать ядро в контейнера, то можно попробовать runtime kata containers. В katacontainer больше изоляции от хостовой системы, но более долгий запуск контейнеров. 

---


* Создайте кастомные образы nginx и php, объедините их в docker-compose.
После запуска nginx должен показывать php info.
Все собранные образы должны быть в docker hub


## Решение.

### 1. Образ Nginx

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

[Репозиторий с образом](https://hub.docker.com/repository/docker/azatrg/nginx)


**Ответы на вопросы**

1. Определите разницу между контейнером и образом.

Образ - это что-то вроде шаблона из которого запускатся контейнер. Можно использовать готовые образы или создавать свои на основе существующих. 
Контейнер это запущенный образ. При запуске можно задать настройки сети, портов, имени и внести некоторые изменения в файловую систему образа(так называемый верхний слой, доступный для записи).

2. Можно ли в контейнере собрать ядро. 

Скорее всего нет. Считаю что это не нужно т.к. контейнер использует ядро хостовой системы и в этом нет никакого смысла.


### * Docker compose

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


