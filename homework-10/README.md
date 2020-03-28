# Домашнее задание ansible

Домашнее задание считается принятым, если:
- предоставлен Vagrantfile и готовый playbook/роль ( инструкция по запуску стенда, если посчитаете необходимым )
- после запуска стенда nginx доступен на порту 8080
- при написании playbook/роли соблюдены перечисленные в задании условия

Критерии оценки: Ставим 5 если создан playbook - Выполнено. [Ссылка на playbook](https://raw.githubusercontent.com/azatrg/OTUS-Linux-Homework/master/homework-10/ansible_books/nginx.yml)
Ставим 6 если написана роль - Выполнено. [Ссылка на роль](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-10/nginx-role)

---

## Решение



1. Скопировать файлы из [репозитория](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-10). Перейти в папку homework-10. 
Структура с описанием файлов.

```
├── ansible_books		# Папка с плейбуками
│   ├── nginx_run_role.yml	# это плейбук запускает роль nginx-role
│   └── nginx.yml		# Это просто плейбук (все в одном файле)
├── ansible.cfg			# Конфиг ансибла
├── inventory			# Файл inventory
├── nginx-role			# Папка с ролью
│   ├── defaults
│   │   └── main.yml		# Переменные
│   ├── handlers
│   │   └── main.yml		# Обработчики
│   ├── meta
│   │   └── main.yml		
│   ├── README.md
│   ├── tasks
│   │   └── main.yml		# Задачи
│   ├── templates
│   │   └── nginx.conf.j2	# Шаблон конфига	
│   ├── tests
│   │   ├── inventory
│   │   └── test.yml
│   └── vars
│       └── main.yml
├── README.md
├── templates
│   └── nginx.conf.j2
└── Vagrantfile
```

Провижен через ansible прописан в [Vagrantfile](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-10). По умолчанию запуститься через роль. Если надо проверить провижен через плейбук, то перед провиженом надо заменить строку в Vagrantfile
```
ansible.playbook = "ansible_books/nginx_run_role.yml"
```
на
```
ansible.playbook = "ansible_books/nginx.yml"
```


2. Запустить вагрант файл без провижена. Запустить без provision надо для того чтобы проверить и поправить если это необходимо настройки хоста в файле inventory.
```
vagrant up --no-provision
```
3. Выполнить команду **vagrant ssh-config** , убедиться что значения *Hostname*, *Port* и *IdentityFile* равны значениям *ansible_host*, *ansible_port* и *ansible_private_key_file* соответвенно. Скорее всего будет отличатся только путь к файлу с ключем. Можно выполнить команду для его замены в файле inventory из вывода ssh-config.

```
sed -i "s|\(^.*ansible_private_key_file=\).*$|\1$(vagrant ssh-config | awk '/IdentityFile/{print $2}')|" inventory
```
Если другие поля не совпадают их можно поправить ручками

4. После того как убедились что inventory корректен можно запустить provision командой.

```
vagrant provision
```

5. Проверить что nginx запущен и слушает на порту 8080

```
curl -I 192.168.8.100:8080
```
или открыв в браузере.
