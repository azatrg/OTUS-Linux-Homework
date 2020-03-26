# Домашнее задание ansible


---

1. Скопировать файлы из репозитория
2. Запустить вагрант файл без провижена
```
vagrant up --no-provision
```
3. Затем заменить путь к ключу ssh в файле inventory
```
sed -i "s|\(^.*ansible_private_key_file=\).*$|\1$(vagrant ssh-config | awk '/IdentityFile/{print $2}')|" inventory
```
