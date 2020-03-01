# Загрузка система

---

## Домашнее задание

1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

4(\*). Сконфигурировать систему без отдельного раздела с /boot, а только с LVM
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/
PV необходимо инициализировать с параметром --bootloaderareasize 1m
Критерии оценки: Описать действия, описать разницу между методами получения шелла в процессе загрузки.
Где получится - используем script, где не получается - словами или копипастой описываем действия.

---

## Решение

### 1. Попасть в систему без пароля несколькими способами
#### 1й-способ init=/bin/bash

1. В окне выбора ОС загрузчика нажать **e**. В конце строки начинающейся с linux16 добавить вместо **rhgb quiet** **init=/bin/sh**, также удалил все между ro и crashkernel=auto. Нажать **ctrl+x** для загрузки с изменными параметрами. После этого я попадаю в систему сразу в оболочку sh. 
2. Выполнив **mount | grep LogVol00** можно увидеть что рутовая фс подмонтировалась только на чтение. Для того чтобы можно было внести изменения монтирую ее как rw.
```
mount -o remount,rw /
```
3. Тепеорь могу поменять пароль пользователя root выполнив команду **passwd**
Сообщение 
```
passwd: all authentication tokens updated successgully
```
говорит о том что пароль изменен.

4. Так как в Centos7 по дефолту включен SELinux в enforcing mode надо создать файл в корне скрытый файл .autorelabel. Это позволит принять изменения в /etc/shadow

```
touch /.autorelabel
```

5. Для перезагрузки выполняю

```
exec /sbin/init 6
```

6. После перезагрузки успешно захожу в систему с новым паролем=)

#### 2й способ rd.break

1. Также как и в первом способе в в конце строки начинающейся с linux16 дописываю, но уже **rd.break** . Также жму **ctrl+x**
Попадаю в emergency mode. Также как и в первом случае корневая фс в режиме read-only.

2. Монтирую файловую систему в режиме чтения-записи в /sysroot командой
```
mount -o remount,rw /sysroot
``` 
3. И делаю папку /sysroot корневой 
```
chroot /sysroot
```
4. Меняю пароль рута
```
passwd root
```
5. Создаю файл .autorelabel для SELinux
```
touch /.autorelabel
```
6. Выхожу из chroot 2 раза введя exit для перезагруки системы. 
7. Захожу в систему в новым паролем

#### 3й Способ. rw init=/sysroot/bin/sh
1. В строке начинающейся с linux16 меняю ro на rw init=sysroot/bin/sh (не в конце, а сразу после rw см.скртншот). Нажимаю ctrl+x для загрузки системы
2. Почему-то этот способ не сработал сразу, а именно не срабатывал .autorelabel. Погуглив обнаружил что при повторной загрузке надо удалить **console=ttyS0,115220** из grub где прописано ядро. После этого autorelabel отработал и я смог зайти с новаым паролем.

---

### Установить систему с LVM и переименовать VG

1. Сначала смотрим на текущее имя volume group
```
sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 

```
Имя - VolGroup00

Также надо обратить внимание на то куда подмонтировал swap файл, если на ту же VolumeGroup, то надо его предварительно отключить, чтобы он не вызвал зависание при перезагруке т.к. после переименования система будет пытаться его отмонтировать по старому пути.
```
cat /etc/fstab | grep swap
sudo swapoff /dev/mapper/VolGroup00-LogVol01
```

2. Переменуем VG командой

```
sudo vgrename VolGroup00 MYLVM
  Volume group "VolGroup00" successfully renamed to "MYLVM"
```
3. Теперь надо внести изменения в файлы /etc/fstab, /etc/default/grub , /boot/grub2/grub.cfg. Быстрее всего сделать это с помощью sed.
```
sudo sed -i 's/VolGroup00/MYLVM/g' /etc/fstab /etc/default/grub /boot/grub2/grub.cfg
```
4. Также надо пересоздать initrd.

```
sudo mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
```

5. После этого можно перезагрузиться и проверить.

---

### Добавить модуль в initrd

1. В папке /usr/lib/dracut/modules.d/ создам папку для модуля с именем 01test
```
mkdir /usr/lib/dracut/modules.d/01test
```
2. Помещу туда 2 скрипта.
1-й module-setup.sh нужен для установки модуля. Следующего содержания.
```
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
```
2-й Скрипт, который будет вызываться при загрузке. Следующего содержания.
```
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```
3. пересобираю initramfs

```
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
``` 

4. Проверяю что модуль есть в только что созданной initramf
```
lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
```
Если все ок, то выведет строку *test*

5. Включу в файле /boot/grub2/grub.cfg подробный лог при загрузке убрав "rghb quiet"
6. Перезагружусь и в окне virtualbox увижу пингвинчика из файла test.sh. Модуль быьл успешно добавлен в initramfs.
