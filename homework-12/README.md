# SELinux

## Домашнее задание

1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/blob/master/selinux_dns_problems/
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.
Критерии оценки:
Обязательно для выполнения:
- 1 балл: для задания 1 описаны, реализованы и продемонстрированы все 3 способа решения;
- 1 балл: для задания 2 описана причина неработоспособности механизма обновления зоны;
- 1 балл: для задания 2 реализован и продемонстрирован один из способов решения;
Опционально для выполнения:
- 1 балл: для задания 2 предложено более одного способа решения;
- 1 балл: для задания 2 обоснованно(!) выбран один из способов решения.


## Решение

### переключатель setsebool
1.1.1  Поменяю порт который слушает nginx в конфиге /etc/nginx/nginx.cong

```
    server {
        listen       80 default_server;

```
на
```
    server {
        listen       8088 default_server;

```
1.1.2 Служба не запуститься из-за selinux. Для траблшутинга надо смотреть лог - /var/log/audit/audit.log . По его содержанию понятно только что nginx запрещен запуск на нестандартном порту политикой selinux. Самый простой способ найти решение, это воспользоваться утилитой audit2why из пакета **policycoreutils-python** что я и сделаю.

```
audit2why < /var/log/audit/audit.log 
type=AVC msg=audit(1587596681.711:1416): avc:  denied  { name_bind } for  pid=12547 comm="nginx" src=8088 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
```

1.1.3 Делаю как и советует audit2why

```
setsebool -P nis_enabled 1
```
Прикладываю скриншот.

### Добавление порта в имеющийся тип

1.2.1 Найду нужный мне тип

```
semanage port -l | grep  http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
1.2.2 Нужный мне тип http_port_t. Добавляю в него порт 8088.

```
semanage port -a -t http_port_t -p tcp 8088
```

1.2.3 Перезапускаю nginx. Но перед этим возвращаю значение nis_enabled на 0 для того чтобы сработал именно способ с добавлениме порта. 

Прикладываю скриншот.

### Формирование и установка модуля SELinux

1.3.1 Перед формированием модуля удалю порт из типа добавленный в редудыщей части.

```
setsebool -P nis_enabled 0
```
1.3.2 Сформирую модуль с именем httpd_add_port c помощью audit2allow

```
audit2allow -M httpd_add_port --debug < /var/log/audit/audit.log
```
Содержимое файла 

```
cat httpd_add_port.te 

module httpd_add_port 1.0;

require {
	type httpd_t;
	type unreserved_port_t;
	class tcp_socket name_bind;
}

#============= httpd_t ==============

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow httpd_t unreserved_port_t:tcp_socket name_bind;

```

```
semodule -i httpd_add_port.pp
```

Прикладываю скриншот.

## Часть 2

---

Проверить **semanage permissive -a named_t** , но это не лучше чем setenforce 0

---


1. Поднял стенд  с dns. Попытался внести изненение в зону с клиента по инструкции.
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
>
```
2. Ошибка на сервере, поэтому иду туда смотреть в /var/log/audit/audit.log . Там вижу следующее

```
[root@ns01 vagrant]# cat /var/log/audit/audit.log 

type=AVC msg=audit(1587806218.533:1977): avc:  denied  { create } for  pid=7143 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0
type=SYSCALL msg=audit(1587806218.533:1977): arch=c000003e syscall=2 success=no exit=-13 a0=7fd7de774050 a1=241 a2=1b6 a3=24 items=0 ppid=1 pid=7143 auid=4294967295 uid=25 gid=25 euid=25 suid=25 fsuid=25 egid=25 sgid=25 fsgid=25 tty=(none) ses=4294967295 comm="isc-worker0000" exe="/usr/sbin/named" subj=system_u:system_r:named_t:s0 key=(null)
type=PROCTITLE msg=audit(1587806218.533:1977): proctitle=2F7573722F7362696E2F6E616D6564002D75006E616D6564002D63002F6574632F6E616D65642E636F6E66

```
3. Понятно только что selinux что-то заблокировал для pid 7143 это собственно и есть служба днс сервера.

4. Воспользуюься audit2why для более понятного вывода ошибки поиска решения.

```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log 
type=AVC msg=audit(1587806218.533:1977): avc:  denied  { create } for  pid=7143 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```
5. Сгенерировал модуль, установил, но ошибка осталась. В логах появилась новая ошибка. Поменялся только t_context

```

```
не мог dir search

И еще один запрет
```
audit2why < /var/log/audit/audit.log 
type=AVC msg=audit(1587810850.451:32): avc:  denied  { read } for  pid=1532 comm="isc-worker0000" name="ip_local_port_range" dev="proc" ino=18672 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:sysctl_net_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```
не может file read

и еще
```
type=AVC msg=audit(1587811253.324:32): avc:  denied  { open } for  pid=1532 comm="isc-worker0000" path="/proc/sys/net/ipv4/ip_local_port_range" dev="proc" ino=18673 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:sysctl_net_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1587811253.333:33): avc:  denied  { open } for  pid=1532 comm="isc-worker0000" path="/proc/sys/net/ipv4/ip_local_port_range" dev="proc" ino=18673 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:sysctl_net_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```

и еще 

```
type=AVC msg=audit(1587811576.257:32): avc:  denied  { getattr } for  pid=1530 comm="isc-worker0000" path="/proc/sys/net/ipv4/ip_local_port_range" dev="proc" ino=18672 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:sysctl_net_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```

Теперь вообще перестало писать в audit.log 

---

6. Как вариант попробую запустить named в permissive domain (отключу selinux для конкретной службы).

```
semanage permissive -a named_t
systemctl restart named
```
не помогло

---

Попытка №2 

1. Воспользуюсь утилитой sealert

```
sealert -a /var/log/audit/audit.log 

```
Вывод команды:
```
100% done
found 1 alerts in /var/log/audit/audit.log
--------------------------------------------------------------------------------

SELinux запрещает /usr/sbin/named доступ create к файл named.ddns.lab.view1.jnl.

*****  Модуль catchall_labels предлагает (точность 83.8)  ********************

Если вы хотите разрешить named иметь create доступ к named.ddns.lab.view1.jnl $TARGET_УЧЕБНЫЙ КЛАСС
То необходимо изменить метку на named.ddns.lab.view1.jnl
Сделать
# semanage fcontext -a -t FILE_TYPE 'named.ddns.lab.view1.jnl'
где FILE_TYPE может принимать значения: dnssec_trigger_var_run_t, ipa_var_lib_t, krb5_host_rcache_t, krb5_keytab_t, named_cache_t, named_log_t, named_tmp_t, named_var_run_t, named_zone_t. 
Затем выполните: 
restorecon -v 'named.ddns.lab.view1.jnl'


*****  Модуль catchall предлагает (точность 17.1)  ***************************

Если вы считаете, что named должно быть разрешено create доступ к named.ddns.lab.view1.jnl file по умолчанию.
То рекомендуется создать отчет об ошибке.
Чтобы разрешить доступ, можно создать локальный модуль политики.
Сделать
allow this access for now by executing:
# ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000
# semodule -i my-iscworker0000.pp

```

2. Попробую первый способ.

semanage fcontext -a -t named_cache_t "/etc/named/dynamic(/.*)?" 
restorecon -v /etc/named/dynamic

Также полезно при поиске
```
sesearch -A -s named_t | grep cache
semanage fcontext -l | grep named
```
