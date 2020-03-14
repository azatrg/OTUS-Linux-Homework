# Управление пакетами

---

## Домашнее задание

1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
2) создать свой репо и разместить там свой RPM
реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо

* реализовать дополнительно пакет через docker

---
## Решение.

1. Прикладываю [SPEC-файл](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-8/lighttpd.spec) и собранный [RPM c веб-сервером lighttpd](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-8/RPM/lighttpd-1.4.54-1.el7.x86_64.rpm) . Подробное описание сборки ниже.

2. Скопировать себе  все файлы из [папки c ДЗ](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-8). Запустить Vagrantfile

```
vagrant up
```
Проверить что репозиторий подключен и там есть пакет

```
yum repolist enabled | grep otus
```
Можно отключить epel и поставить пакет из локального репозиторий
```
yum-config-manager --disable epel
yum install -y lighttpd
```


---

### Подробное описание решения

##### 1. Собрать свой RPM.

1. Для сборки RPM установить пакеты:

```
sudo yum install -y tree mc redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
```

2. Буду собирарать вебсервер lighttpd с поддержком memcached . Для этого качаю SRPM пакет lighttpd с помощью yumdownloader.

```
yumdownloader --source lighttpd
```

3. ЗАпускаю установку rpm -i . Система ругается на отсутсвие пользвателя builder, но файлы распаковывает в папку rpmbuild

```
rpm -i lighttpd-1.4.54-1.el7.src.rpm 
```
4. Внесу следующие изменения в файл rpmbuild/SPECS/lighttpd.spec

В секцию %build %configure добавлю

```
 	--with-memcached
```
В секцию BuildRequires добавлю

```
BuildRequires: libmemcached-devel
```

Итоговый spec-файл 

5. Ставлю все зависимости перез сборкой.

```
sudo yum-builddep rpmbuild/SPECS/lighttpd.spec
```

6. Запускаю сборку пакета

```
rpmbuild -bb rpmbuild/SPECS/lighttpd.spec
```

7. Итоговый пакет лежит в папке **rpmbuild/RPMS/x86_64/**


8. Установлю собранный пакет. Использую yum **localinstall**, потому что он в отличии от **rpm -i** найдет и установит зависимости пакета. 

```
sudo yum localinstall lighttpd-1.4.54-1.el7.x86_64.rpm
```
9. Проверка того что пакет собран с memcached

```
lighttpd -V | grep memcached
	+ memcached support
```

---


#### 2.создать свой репо и разместить там свой RPM

1. Установлю nginx

```
sudo yum install -y epel-release && sudo yum install -y nginx
```
2. Создам в рабочей директории nginx папку для репозитория

```
mkdir /usr/share/nginx/html/repo
```
3. Скопирую туда собранные пакеты.

```
cp rpmbuild/RPMS/x86_64/\*.rpm /usr/share/nginx/html/repo/
```
4. Проинициализирую репозиторий командой

```
createrepo /usr/share/nginx/html/repo/
```

5. Включу опцию autoindex on в nginx

```
location / {
                root /usr/share/nginx/html;
                index index.html index.htm;
                autoindex on;
        }

```
6. Перезапускаю nginx

```
sudo systemctl restart nginx
```
7. Проверяю в браузере пройдя по ссылке - http://192.168.11.102/repo/

8. Теперь подключу свой репозиторий к yum. Создам файл - 

````
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=azat-otus
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

9. Проверю что репозиторий подключился

```
yum repolist enabled | grep otus
```

10. Для установки пакета lighttpd из локального репозитония надо отключить репозиторий epel

```
yum-config-manager --disable epel
```
и установить lighttpd


