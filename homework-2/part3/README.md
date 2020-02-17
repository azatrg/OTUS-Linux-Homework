### Перенос работающей системы на RAID1

## ЗАдача

 - [ ] перенесети работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверики принимается вывод команды lsblk до и после и описание хода решения (можно воспользовать утилитой Script).

## Решение

1. Дано 2 диска /dev/sda с установленной системой и чистый диск /dev/sdb такого же размера. Вывод команды lsblk.

```

```

2. Установить mdadm, rsync и e2fsprogs т.к их нет в образе.

3. от рута запуска sfdisk -d /dev/sda | sfdisk /dev/sdb
Вывод:
```
[root@azatrg-raid10 vagrant]# sfdisk -d /dev/sda | sfdisk /dev/sdb
Checking that no-one is using this disk right now ...
OK

Disk /dev/sdb: 5221 cylinders, 255 heads, 63 sectors/track
sfdisk:  /dev/sdb: unrecognized partition table type

Old situation:
sfdisk: No partitions found

New situation:
Units: sectors of 512 bytes, counting from 0

   Device Boot    Start       End   #sectors  Id  System
/dev/sdb1   *      2048  83886079   83884032  83  Linux
/dev/sdb2             0         -          0   0  Empty
/dev/sdb3             0         -          0   0  Empty
/dev/sdb4             0         -          0   0  Empty
Warning: partition 1 does not end at a cylinder boundary
Successfully wrote the new partition table

Re-reading the partition table ...

If you created or changed a DOS partition, /dev/foo7, say, then use dd(1)
to zero the first 512 bytes:  dd if=/dev/zero of=/dev/foo7 bs=512 count=1
(See fdisk(8).)
```

4. Изменить тип раздела на втором диске на Linux RAID autodetect - его код fd. Делаю это с помощью fdisk. 

5. Создать RAID1 в degraded состоянии т.к. пока первый диск содержит ОС и используется для загрузки.

```
mdadm --create /dev/md0 --level=1 --raid-devices=2 missing /dev/sdb1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? y
mdadm: Fail create md0 when using /sys/module/md_mod/parameters/new_array
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

6. Проверю состояние массива.
```
cat /proc/mdstat
```
7. Отформатирую созданный массив в ext4
```
mkfs.ext4 /dev/md0
```
8. Монтирую raid в /mnt/
```
mount /dev/md0 /mnt/
```
9. И копирую туда все файлы текущей системы, кроме файлов из директорий /dev,/proc,/sys,/tmp,/mnt. 
```
rsync -auxHAXSv --exclude=/dev/* --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/mnt/* /* /mnt
```
10. Монтирую те разделы которые я не скопировал а /mnt
```
mount --bind /proc /mnt/proc
mount --bind /dev /mnt/dev
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run
```
11. Делаю chroot в /mnt/

```
chroot /mnt/
```
12. Редактирую fstab. Изменяю на UUID массива /dev/md0


13. Создаю mdadm.conf  с текущей конфигурацией raid.

```
mdadm --detail --scan > /etc/mdadm.conf
```

14. Тут как я понял делается бэкап initramfs, потом в него вносятся изменения (загрузка с raid) и он пересобирается.

```
dracut --mdadmconf --fstab --add="mdraid" --filesystems "xfs ext4 ext3" --add-drivers="raid1" --force \            
 /boot/initramfs-$(uname -r).img $(uname -r) -M

```
15. Редактирую загрузчик 

```
vim /etc/default/grub
```
Изменю строку
GRUB_CMDLINE_LINUX="crashkernel=auto rd.auto rd.auto=1 rhgb quiet"
Добавлю строку
GRUB_PRELOAD_MODULES="mdraid1x"

16. Создаю новый конфиг для grub и ставлю его на диск /dev/sdb
```
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-install /dev/sdb
```
17. Теперь надо перезагрузить компьютер и выбрать загрузку со второго диска в биосе.

18. После загрузки системы включаю своп и проверяю точки монтирования и состояние raid

```
swapon -s
mount -t ext4
cat /proc/mdstat
```

```
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0         40G  871M   37G   3% /
devtmpfs        488M     0  488M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  490M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
tmpfs           100M     0  100M   0% /run/user/1000
```
Как видно корень подмонтирован на raid.

19. Теперь надо добавить второй диск в массив. Для этого меняю тип партиции на fd (Linux raid autodetect).


20. Добавляю диск /dev/sda1 в raid.
```
sudo mdadm --manage /dev/md0 --add /dev/sda1
```
и наблюдаю статус сборки рейда.
```
watch -n1 "cat /proc/mdstat"
```
21. Также не забываю поставить обновленный grub на добавленный в raid диск.

```
grub2-istall /dev/sdb
```

22. Вывод команды lsblk

```
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk  
`-sda1    8:1    0  40G  0 part  
  `-md0   9:0    0  40G  0 raid1 /
sdb       8:16   0  40G  0 disk  
`-sdb1    8:17   0  40G  0 part  
  `-md0   9:0    0  40G  0 raid1 /
```


