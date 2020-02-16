# Практика с LVM

 - [ ] манипуляции с томами
 - [ ] btrfs/zfs

---

## Манипуляции с LVM

### Уменшить том под / до 8G

1. Для начала надо посмотреть какие диски\разделы есть в наличии - команды *lsblk* и *lvmdiskscan*
2. Для выполнения задания без LiveCD понадобиться пакет xfsdump для снятия дампа с / на котором fs - xfs. Лучше сразу поставить его через Vagrant provision.
```
sudo yum install -y xfsdump
```
3. подготовлю LVM том для / раздела и подмонитирую его в mount
```
sudo pvcreate /dev/sdb
sudo vgcreate vg_root /dev/sdb
sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root
sudo mkfs.xfs /dev/vg_root/lv_root
sudo mount /dev/vg_root/lv_root /mnt
```
4. Скопирую все данные с корня во временную папку созданную ранее.
```
sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt
```
5. Подмонтирую текущие папки /proc /sys / run /boot /dev в /mnt и сделаю chroot

```
sudo -s
for i in /proc/ /sys/ /dev/ /run/ /boot/;do mount --bind $i /mnt/$i; done
chroot /mnt
```
6. Поменяю конфиг grub, для загрузки из нового / 

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

7. Обновлю initrd.

```
cd /boot/; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;done
```
8. После этого в файле /boot/grub2/grub.cfg меняю rd.lvm/lv= со старого / на новый (временный). Выхожу из chroot.  И перезагружаюсь.

```
exit
shutdown -r now
```
9. Проверяю что я загрузился с другого partition. 

```
lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lb_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

10. Удаляю раздел на 40G и создаю вместо него на 8G c таким же именем

```
sudo lvremove /dev/VolGroup00/LogVol00
sudo lvcreate -n  LogVol00 -L 8G /dev/VolGroup00
```

11. Теперь создаю на новом разделе ФС , монтирую его в /mnt и копирую все данные с текущего корневого раздела  командой xfsdump

```
sudo mkfs.xfs /dev/VolGroup00/LogVol00
sudo mount /dev/VolGroup00/LogVol00 /mnt
sudo xfsdump -J - /dev/vg_root/lb_root | sudo xfsrestore -J - /mnt
```
12. Перенастраиваю grub, кроме изменеия файла grub.cfg

```
sudo -s
for i in /proc/ /sys/ /dev/ /run/ /boot/;do mount --bind $i /mnt/$i; done
chroot /mnt
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot/; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force;done
```
13. Не перезагружаюсь и не выхожу из chroot т.к сейчас можно еще перенести том под /var

### Выделить том под /var в зеркало.

1. На свободных дисках создам зеркало. Сначала добавляю эти диски в pv, затем создам новую vg под /var  и сразу их туда добавлю. Затем создам lv c зеркалом (ключ -m1).

```
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var
```
2. Создам ФС на созданом lv и скопирую туда /var

```
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
rsync -avHPSAX /var/ /mnt/
```

3. На всякий случай сохраняю старый /var в /tmp/oldvar и монтирую новый /var

```
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
umount /mnt/
mount  /dev/vg_var/lv_var /var
```
4. И добавляю новый /var в fstab для автоматического монтирования при перезагрузке.

```
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

5. Выхожу из chroot, перезагружась. После перезагрузки проверяю что все ок.

```
exit
shutdown -r now
```
```
lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
└─vg_root-lb_root        253:7    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:2    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:3    0  952M  0 lvm  
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:4    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:5    0  952M  0 lvm  
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk 

 df -Th
Filesystem                      Type      Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00 xfs       8.0G  760M  7.3G  10% /
devtmpfs                        devtmpfs  110M     0  110M   0% /dev
tmpfs                           tmpfs     118M     0  118M   0% /dev/shm
tmpfs                           tmpfs     118M  4.6M  114M   4% /run
tmpfs                           tmpfs     118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       xfs      1014M   61M  954M   6% /boot
/dev/mapper/vg_var-lv_var       ext4      922M  135M  724M  16% /var

```

6. Удаляю временный том lb_root.

```
sudo lvremove /dev/vg_root/lb_root
sudo vgremove vg_root
sudo pvremove /dev/sdb
```

### Выделить том под /home

1. Том под /home буду создавать в освободившемся vg VolGroup00 

```
sudo lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
sudo mkfs.ext4 /dev/VolGroup00/LogVol_Home
```
2. Монтирую в /mnt, копирую туда содержимое папки /home 
```
sudo mount /dev/VolGroup00/LogVol_Home /mnt
sudo rsync -avHPSAX /home/* /mnt/
```
3. Удалаю старый /home и размонтирую новый из /mnt чтобы смонтировать его в /home
```
sudo rm -rf /home/*
sudo umount /mnt
sudo mount /dev/VolGroup00/LogVol_Home /home/
```

4. Добавляю в fstab для автоматического монтирования.
```
echo "`blkid | grep Home: | awk '{print $2}'` /home ext4 defaults 0 0" | sudo tee -a /etc/fstab
```

### Том для снэпшотов.

1. Сгенерирую файлы в /home

```
touch /home/vagrant/file{1..50}
```

2. Сниму снэпшот

```
sudo lvcreate -L 100MB -s -n snap_home /dev/VolGroup00/LogVol_Home
```
3. Удалю часть файлов.

```
rm -f /home/vagrant/file{12..25}
```

4. Восстановлю данные со снэпшота.
```
sudo umount /home
sudo lvconvert --merge /dev/VolGroup00/snap_home
sudo mount /home
```



