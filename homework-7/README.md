# Инициализация системы. Systemd и SysV

---

## Домашнее задание

Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):
1. Создать сервис и unit-файлы для этого сервиса:
- сервис: bash, python или другой скрипт, который мониторит log-файл на наличие ключевого слова;
- ключевое слово и путь к log-файлу должны браться из /etc/sysconfig/ (.service);
- сервис должен активироваться раз в 30 секунд (.timer).

2. Дополнить unit-файл сервиса httpd возможностью запустить несколько экземпляров сервиса с разными конфигурационными файлами.

3. Создать unit-файл(ы) для сервиса:
- сервис: Kafka, Jira или любой другой, у которого код успешного завершения не равен 0 (к примеру, приложение Java или скрипт с exit 143);
- ограничить сервис по использованию памяти;
- ограничить сервис ещё по трём ресурсам, которые не были рассмотрены на лекции;
- реализовать один из вариантов restart и объяснить почему выбран именно этот вариант.
-\* реализовать активацию по .path или .socket.

4\*. Создать unit-файл(ы):
- сервис: демо-версия Atlassian Jira;
- переписать(!) скрипт запуска на unit-файл.


---


## Решение.
***Часть 1-2.*** Склонировать [репозиторий](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-7/Vagrantfile) со всеми файлами. Запустить [Vagrantfile](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-7/Vagrantfile). 
```
vagrant up
```
После окончания провиженинга
```
vagrant ssh
```
Просмотр срабатывания таймера
```
sudo tail -f /var/log/messages 
Mar  9 18:06:56 localhost systemd: Removed slice User Slice of vagrant.
Mar  9 18:07:25 localhost systemd: Starting My watcher service...
Mar  9 18:07:25 localhost root: Mon Mar  9 18:07:25 UTC 2020: I found word, Master!
Mar  9 18:07:25 localhost systemd: Started My watcher service.
Mar  9 18:07:39 localhost systemd: Created slice User Slice of vagrant.
Mar  9 18:07:39 localhost systemd: Started Session 4 of user vagrant.
Mar  9 18:07:39 localhost systemd-logind: New session 4 of user vagrant.
Mar  9 18:07:55 localhost systemd: Starting My watcher service...
Mar  9 18:07:55 localhost root: Mon Mar  9 18:07:55 UTC 2020: I found word, Master!
Mar  9 18:07:55 localhost systemd: Started My watcher service.
Mar  9 18:08:25 localhost systemd: Starting My watcher service...
Mar  9 18:08:25 localhost root: Mon Mar  9 18:08:25 UTC 2020: I found word, Master!
Mar  9 18:08:25 localhost systemd: Started My watcher service.
Mar  9 18:08:55 localhost systemd: Starting My watcher service...
Mar  9 18:08:55 localhost root: Mon Mar  9 18:08:55 UTC 2020: I found word, Master!
Mar  9 18:08:55 localhost systemd: Started My watcher service.
Mar  9 18:09:25 localhost systemd: Starting My watcher service...
Mar  9 18:09:25 localhost root: Mon Mar  9 18:09:25 UTC 2020: I found word, Master!
Mar  9 18:09:25 localhost systemd: Started My watcher service.
```
2 Сервиса httpd на разных портах
```
sudo ss -antulp | grep -E "80|8080"
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=6052,fd=4),("httpd",pid=6051,fd=4),("httpd",pid=6050,fd=4),("httpd",pid=5959,fd=4),("httpd",pid=5958,fd=4),("httpd",pid=5957,fd=4),("httpd",pid=5956,fd=4),("httpd",pid=5955,fd=4),("httpd",pid=5954,fd=4),("httpd",pid=5953,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=6063,fd=4),("httpd",pid=6062,fd=4),("httpd",pid=6061,fd=4),("httpd",pid=6060,fd=4),("httpd",pid=6059,fd=4),("httpd",pid=6058,fd=4),("httpd",pid=5950,fd=4),("httpd",pid=5948,fd=4),("httpd",pid=5947,fd=4),("httpd",pid=5945,fd=4),("httpd",pid=5944,fd=4),("httpd",pid=5943,fd=4))

``` 
или
```
systemctl status httpd@first && systemctl status httpd@second
```

**часть 3**. [Jira Unit](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-7/jira.service).
[Описание](### 3. Создать unit-файлы для сервиса:)



---

### 1. Создать сервис и unit-файлы для этого сервиса.

1. Так как я пишу "полноценный" сервис, то его конфиг будет распологаться как и полагаеться в папке /etc/sysconfig/

```
sudo vi /etc/sysconfig/watcher.conf
```
следующего содержания
```
#Configuration file for my watcher service
# Place it in /etc/sysconfig

#File and word in file to monitor
WORD="ALERT"
LOG=/var/log/watcher.log
```
2. Затем создаю файл /var/log/watchlog.log в его содержимом дотаточно одного вхождения слова ALERT.
```
echo ALERT >> /var/log/watcher.log
```
3. Создам скрипт /opt/watcher.sh следующего содержания:
```
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```
При нахождении ключевого слова команда logger отправить сообщение с датой и временем выполнения в системный журнал.
Обязательно делаю скрипт исполняемым

4. Создам юнит для сервиса. man systemd.unit говорит что это надо делать в папке - /lib/systemd/system/

5. Создам юнит для таймера тамже.

6. Запущу timer

```
systemctl start watcher.timer
```
После daemon-reload заработал + исправил одну свою ошибку, но почему-то скрипт\таймер отрабатывает не каждые 30 секунд
добавить AccuracySec=1us

---

### 2. Дополнить unit-файл сервиса httpd возможностью запустить несколько экземпляров сервиса с разными конфигурационными файлами.

1. Устанавливаю необходимые пакеты

```
sudo yum install epel-release -y && sudo yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
2. РАскомментирую строки SOCKET и OPTIONS в файле /ets/sysconfig/spawn-fcgi

3. Напишу юнит для spawn-fcgi

```
[Unit]
Description=Spawn-fcgi startup service
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target

```
4. Запускаю написанный сервис

```
sudo systemct start spawn-fcgi
sudo systemctl status spawn-fcgi
```

5. Добавлю в юнит файл сервиса httpd параметр %I , также переименую его в httpd@.service.


```
EnvironmentFile=/etc/sysconfig/httpd-%I
```
```
mv /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service 
```


6. Создам 2 файла окружения а которых укажу путь к конфигам.

```
sudo mv /etc/sysconfig/httpd /etc/sysconfig/httpd-first
sudo cp /etc/sysconfig/httpd-first /etc/sysconfig/httpd-second
```
7. В каждом из конфигов раскомментирую строку 
```
OPTIONS=-f conf/first.conf
```
и 
```
OPTIONS=-f conf/second.conf
```
8. Создам 2 конфига с папке /etc/httpd/conf/

```
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf                            
sudo mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```

во второй файл внесу следующие изменения для того чтобы второй жкземпляр слушал отдельный порт и имел отдельный pid файл.

```
PidFile	/var/run/httpd-second.pid
Listen 8080
```

9. Проверю что оба экземпляра запущены

```
ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=3655,fd=4),("httpd",pid=3654,fd=4),("httpd",pid=3653,fd=4),("httpd",pid=3652,fd=4),("httpd",pid=3651,fd=4),("httpd",pid=3650,fd=4),("httpd",pid=3649,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=3641,fd=4),("httpd",pid=3640,fd=4),("httpd",pid=3639,fd=4),("httpd",pid=3638,fd=4),("httpd",pid=3637,fd=4),("httpd",pid=3636,fd=4),("httpd",pid=3635,fd=4))
```

---
### 3. Создать unit-файлы для сервиса:
- сервис: Kafka, Jira или любой другой, у которого код успешного завершения не равен 0 (к примеру, приложение Java или скрипт с exit 143);
- ограничить сервис по использованию памяти;
- ограничить сервис ещё по трём ресурсам, которые не были рассмотрены на лекции;
- реализовать один из вариантов restart и объяснить почему выбран именно этот вариант.

1. Качаю пробную версию Atlassian Jira с https://www.atlassian.com/ru/software/jira/download
```
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.7.1-x64.bin
```
2. Делаю файл исполняемым и запускаю

```
chmod +x ./atlassian-jira-software-8.7.1-x64.bin 
sudo ./atlassian-jira-software-8.7.1-x64.bin 
```
Далее в мастере отвею на вопросы и жду окончания установки
3. После завершения установки создаю unit файл для сервиса jira следующего содержания.

3.1

```
[Unit]
Description=Atlassian Jira Service
After=network.target

[Service]
Type=forking
User=jira
PIDFile=/opt/atlassian/jira/work/catalina.pid
ExecStart=/opt/atlassian/jira/bin/start-jira.sh
ExecStop=/opt/atlassian/jira/bin/stop-jira.sh

[Install]
WantedBy=multi-user.target
```
Если я остановлю сервис командой *sudo systemctl stop jira*, то сервис перейдет в состояние failed. Это из-за нестандартного кода выхода(143). Если выполнить *systemctl status jira*, то можно увидеть строку.
```
   Active: failed (Result: exit-code) since Sun 2020-03-08 16:14:34 UTC; 3min 2s ago
 Main PID: 4707 (code=exited, status=143)
```
Для того чтобы systemd правильно понимал остановку сервиса добавляю строку
```
SuccessExitStatus=143
```

3.2 Лимиты
1.Ограничить сервис по использования памяти.
Добавить в секцию Service unit-файла 
MemoryLimit=256M
Также добавлю следующие строки в unit файл для ограничения по кол-ву запущенных процессов
LimitNPROC=50
Открытых файлов
LimitNOFILE=1024
Приоритету выполнения
LimitNICE=5

2. После внесения изменений перезагружабю конфиграцию и перезапускаю сервис.

```
sudo systemctl daemon-reload
sudo systemctl restart jira
```

Проверить лимиты можно с помощью команды

```
sudo systemctl show jira | grep -E "MemoryLimit|LimitNPROC|LimitNOFILE|LimitNICE"
```

3. Для перезапуска сервиса добавить 

```
Restart=on-failure
```
Сервис будет перезапускаться только если процесс завершился аварийно. Ненулевой код выхода
