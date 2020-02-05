# ДЗ №1. Обновить ядро в базовой системе.

 - [x] Создать образ с обновленным ядром и загрузить его в Vagrant Cloud. [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-1/Vagrantfile) для запуска.
 - [x] * Собрать ядро из исходников, создал образ с самосборный ядром packer'ом. [Скрипты для сборки vagrantbox](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-1/build-kernel). Vagrantbox залил в vagrant cloud. [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-1/build-kernel/Vagrantfile) для запуска.
 - [ ] ** В созданном мной образе нормально работают VirtualBox Shared Folders.

---

## Основное ДЗ. Создать образ с обновленным ядром

### В процессе сделано
 - Установлен Packer. VirtualBox, Vagrant, Git уже были установлены ранее. В качестве основной ОС использую Ubuntu 18.04 LTS.
 - Выполнено клонирование методички по обновления ядра из [репозитория](https://github.com/dmitry-lyutenko/manual_kernel_update).
 - Выполнено обновление ядра из репозитория elrepo как описано в методичке.
 - Выполнено создание VagrantBox и его загрузка в Vagrant Cloud как описано в методичке.
 - В репозиторий с ДЗ выложен [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-1/Vagrantfile) с моим [образом загруженным в VagrantCloud](https://app.vagrantup.com/azatrg/boxes/centos-7-kernel-v4) .

### Как запустить
```
 vagrant reload
 vagrant up
```
## Как проверить
```
vagrant ssh
uname -r
```
Вывод должен быть таким:
```
4.4.212-1.el7.elrepo.x86_64
```

## Задание со * . Собрать ядро из исходников.

### В процессе сделано.

#### Сначала собрал ручками зайдя на машину по ssh.

 - За основу взял базовый образ Centos 7.
 - Для сборки ядра установил пакеты программ
```
sudo yum -y groupinstall "Development Tools"
sudo yum install -y hmaccalc zlib-devel binutils-devel elfutils-libelf-devel bc openssl-devel wget

```

 - Затем скачал самое новое mainline ядро v5.5, распаковал архив и перешел в распакованную папку
```
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.tar.xz
tar -Jxvf linux-5.5.tar.xz
cd linux-5.5
```
 - Скопировал конфиг текущего ядра и на его основе сделал конфиг для сборки. При этом выбрал опцию olddefconfig для того чтобы все новые функции нового ядра были выставлены в значение по умолчанию. 
```
cp /boot/config* .config &&
make olddefconfig &&
```
 - Собрал ядро и модули
```
sudo make -j 4 &&
sudo make -j 4 modules &&
sudo make -j 4 modules_install &&
sudo make -j 4 install
```
 - Удалил старое ядро, выбрал загрузку нового ядра по умолчанию и перезагрузил машину.
 - После загрузки проверил версию ядра командой *uname -r*

#### На основе приведенного выше примера собрал Vagrant Box.

 - За основу взял те скрипты из методичке по обновлению ядра. Но внес некоторые изменения. 
  -- В json файле для packera.
 1. Задал диск большего размера (30 Гб вместо 10 Гб) потому что при ручной сборке 10 Гб не хватило.
 2. Дал машине 4 cpu для того чтобы использовать make c ключем -j 4. Точное время не засекал, но сборка прошла быстрее.
 3. Дал машине 4 Гб оперативной памяти, но похожу что это не особо повлияло на производительность. 
  -- В первом provision скрипте
 1. Все тоже самое что и при ручной сборке. Файл - 
  -- Во втором скрипте для уменьшения размера образа
 2. Почти все тоже самое что и в методичке, но добавил шаги для удаления установленных для сборки ядра пакетов и исходников самого ядра.

 ```
yum groups remove -y "Development Tools"
yum remove -y hmaccalc zlib-devel binutils-devel elfutils-libelf-devel bc openssl-devel wget

rm  -f /home/vagrant/linux-5.5.tar.xz
rm  -rf /home/vagrant/linux-5.5
 ```
 - Залил [образ c самосборным ядром](https://app.vagrantup.com/azatrg/boxes/centos-7-kernel-5-mainline) в vagrant cloud.
 - Залил [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-1/build-kernel/Vagrantfile) для запуска сомосборного ядра в репозиторий.
