# Фильтрация траффика

## Домашнее задание

1) реализовать knocking port
- centralRouter может попасть на ssh inetrRouter через knock скрипт
пример в материалах
2) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост
3) запустить nginx на centralServer
4) пробросить 80й порт на inetRouter2 8080
5) дефолт в инет оставить через inetRouter

---

## Решение

1. Предварительно на inetrouter включить в настроках sshd password authentication 
2. На inetRouter yастроить iptables
'''

'''