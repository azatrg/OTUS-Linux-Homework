# ДЗ №2. Дисковая подсистема

 - [x] Создать [скрипт](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-2/part2/createraid5.sh) для создания рейда, конф для автосборки рейда при загрузке
 - [x] * [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/blob/master/homework-2/Vagrantfile), который сразу собирает систему с подключенным рейдом
 - [ ] ** перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script). 

---

## Основное задание. Собрать RAID.

### В процессе работы сделано

 - [x] Добавить в Vagrantfile еще дисков.
 - [x] Собрать raid
 - [x] Прописать собранный raid в conf, чтобы raid собирался при загрузке.
 - [x] Сломать, починить raid
 - [x] создать GPT раздел и 5 партиций и смонтировать их на диск

---

#### Добавление дисков в Vagrantfile.

В секцию *:disks => {}* после диска *sata4* добавлю еще один диск(не забыл поставить запятую после *}* ):
```
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 250, # Megabytes
                        :port => 5
		}

```


#### Собрать raid.

1. Сначала проверяю что диски появились в системе.

```
sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        262MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf   disk        262MB VBOX HARDDISK
```

2. Утилита mdadm не установлена по умолчанию, ставлю ее

```
sudo yum install -y mdadm
```

3. перед созданием raid надо занулить superblock

```
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
```

4. Создаю raid

```
sudo mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Fail create md0 when using /sys/module/md_mod/parameters/new_array
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
В данном примере я создаю raid 6 (-l 6)  из 5 дисков (-n 5 /dev/sd{b,c,d,e,f}) . В результате будет создано блочное устройство /dev/md0

5. Для проверки создания raid-массиива использую команды:

```
cat /proc/mdstat
sudo mdadm -D /dev/md0
```

#### Прописать raid в conf.

1. При попытке выполнить *sudo echo* и записать вывод в файл находящийся в /etc получал *Permission denied*. В первый раз решил проблему в лоб.

```
sudo mkdir /etc/mdadm
sudo -s
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf 
```
2. 2-й способ. Более правильный. Погуглив понял что sudo echo не будет работать при записи в системный файл. Обойти это ограничени можно командой tee

```
echo "DEVICE partitions" | sudo tee -a /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf
```




#### Сломать\ починить raid.

1. Искуственно помечу диск как нерабочий

```
sudo mdadm /dev/md0 --fail /dev/sdd
```
2. Для того чтобы посмотреть состояние массивa после выхода ис строя диска использую те же команды

```
cat /proc/mdstat
sudo mdadm -D /dev/md0
```
3. Удаляю сбойный диск

```
sudo mdadm /dev/md0 --remove /dev/sdd
```
4. Потом после физического удаления сломанного диска и добавления вместо него нового диска, добавляю новый диск командой. Как я понимаю в реальной ситуации имя диска может отличаться. Лучше сначала узнать его имя командами *fdisk -l* или *lshw short | grep disk*

```
sudo mdadm /dev/md0 --add /dev/sdd
```

#### Создать GPT

1. Для того чтобы создать разделы как описано в методичке надо установить пакеты parted (для разбивки диска этой утилитой) и e2fsprogs (для форматирования в ext4)

```
sudo yum install -y parted e2fsprogs
```

2. Создам раздел GPT на raid

```
sudo parted -s /dev/md0 mklabel gpt
```
3. Создам партиции
```
sudo parted /dev/md0 mkpart primary ext4 0% 20%
sudo parted /dev/md0 mkpart primary ext4 20% 40%
sudo parted /dev/md0 mkpart primary ext4 40% 60%
sudo parted /dev/md0 mkpart primary ext4 60% 80%
sudo parted /dev/md0 mkpart primary ext4 80% 100%
```

4. Отформатирую эти партиции в ext4

```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
5. Создам каталоги и смонтирую созданные ранее партиции в эти каталоги

```
sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
```
6. Проверю что все партиции успешно подмонтировались.

```
df -h
```

