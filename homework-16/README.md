# otus-linux
Vagrantfile - для стенда урока 9 - Network

# Дано
Vagrantfile с начальным  построением сети
inetRouter
centralRouter
centralServer

тестировалось на virtualbox

# Планируемая архитектура
построить следующую архитектуру

Сеть office1
- 192.168.2.0/26      - dev
- 192.168.2.64/26    - test servers
- 192.168.2.128/26  - managers
- 192.168.2.192/26  - office hardware

Сеть office2
- 192.168.1.0/25      - dev
- 192.168.1.128/26  - test servers
- 192.168.1.192/26  - office hardware


Сеть central
- 192.168.0.0/28    - directors
- 192.168.0.32/28  - office hardware
- 192.168.0.64/26  - wifi

```
Office1 ---\
      -----> Central --IRouter --> internet
Office2----/
```
Итого должны получится следующие сервера
- inetRouter
- centralRouter
- office1Router
- office2Router
- centralServer
- office1Server
- office2Server

# Теоретическая часть
- Найти свободные подсети
- Посчитать сколько узлов в каждой подсети, включая свободные
- Указать broadcast адрес для каждой подсети
- проверить нет ли ошибок при разбиении

# Практическая часть
- Соединить офисы в сеть согласно схеме и настроить роутинг
- Все сервера и роутеры должны ходить в инет черз inetRouter
- Все сервера должны видеть друг друга
- у всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи
- при нехватке сетевых интервейсов добавить по несколько адресов на интерфейс

---

# Решение

## Теоретическая часть

- См. таблицы ниже. Свободные подсети `выделил` и назвал free.
- Ошибок не нашел. Единственное немного запутывает несоответствие 3го октета сети номеру офиса, я бы поменял на office1 - 192.168.1.0/24, office2 - 192.168.2.0/24



1) Сеть Central

| подсеть | кол-во хостов | broadcast | название |
|---|---|---|---|
| 192.168.0.0/28 | 14 | 192.168.0.15  |  directors |
| `192.168.0.16/28 |14 | 192.168.0.31 |   free`|
| 192.168.0.32/28 |14 | 192.168.0.47  |  office hardware|
| `192.168.0.48/28 |14 | 192.168.0.63  |  free`|
| 192.168.0.64/26 |62 | 192.168.0.127  | wifi|
| `192.168.0.128/25 |126 | 192.168.0.255 | free`|

2) Сеть office1

| подсеть | кол-во хостов | broadcast | название |
|---|---|---|---|
|192.168.2.0/26| 62 | 192.168.2.63 | |dev|
|192.168.2.64/26 |62 | 192.168.2.127 |test servers|
|192.168.2.128/26| 62 | 192.168.2.191 |managers|
|192.168.2.192/26| 62  |192.168.2.255  |office hardware|

3) Сеть office2

| подсеть | кол-во хостов | broadcast | название |
|---|---|---|---|
| 192.168.1.0/25 |126 |192.168.1.127 | dev|
|192.168.1.128/26 |62| 192.168.1.191| test servers|
|192.168.1.192/26 |62 | 192.168.1.255 | office hardware|




4) Сеть RouterNet (для линков между роутерами)

- 192.168.255.0/30 - inetRouter <-> centralRouter
- 192.168.255.4/30 - centralRouter <-> office1Router
- 192.168.255.8/30 - centralRouter <-> office2Router


## Практика

Для удобства нарисовал краткую схему с активными хостами. Для подсетей в которых нет хостов добавил на роутеры интерфейсы с ip-адресами.

![Схема](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-16/network.jpg)


И составил таблицу с основными ip и интерфейсами

| host | interface | ip | neighbor\net |
|---|---|---|---|
|inetRouter| eth1 | 192.168.255.1 | centralRouter|
|CentralRouter| eth1 | 192.168.255.2 | inetRouter|
|CentralRouter| eth2 | 192.168.0.1 | centralServer|
|CentralRouter| eth3 | 192.168.0.33 | office hardware|
|CentralRouter| eth4 | 192.168.0.65 | wi-fi|
|CentralRouter| eth5 | 192.168.255.5 | office1Router|
|CentralRouter| eth6 | 192.168.255.9 | office2Router|
|CentralServer| eth1 | 192.168.0.2 | CentralRouter|
|---|---|---|---|
|office1Router| eth2 | 192.168.255.6 |centralRouter |
|office1Router| eth3 | 192.168.2.1 |dev |
|office1Router| eth4 | 192.168.2.65 |office2Server |
|office1Router| eth5 | 192.168.2.129 |managers |
|office1Router| eth6 | 192.168.2.193 |office hardware |
|office1Server| eth1 | 192.168.2.66 |office1Router |
|---|---|---|---|
|office2Router| eth1 | 192.168.255.10 |centralRouter |
|office2Router| eth2 | 192.168.1.1 |dev |
|office2Router| eth3 | 192.168.1.129 |office2Server |
|office2Router| eth4 | 192.168.1.193 |office hardware |
|office2Server| eth1 | 192.168.1.130 |office2Router |


Все маршруты и настройки применяются через shell provision в вагранте. Для проверки можно воспользоваться скриптом pingall.sh