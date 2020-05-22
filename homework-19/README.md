# Домашнее задание

Добавить еще один сервер client2
завести в зоне dns.lab
имена
web1 - смотрит на клиент1
web2 смотрит на клиент2

завести еще одну зону newdns.lab
завести в ней запись
www - смотрит на обоих клиентов

настроить split-dns
клиент1 - видит обе зоны, но в зоне dns.lab только web1

клиент2 видит только dns.lab

*) настроить все без выключения selinux

---

# Решение

1. завести в зоне dns.lab имена:
web1 - смотрит на клиент1
web2 смотрит на клиент2

1.1 Для этого необходимо добавить в файл зоны  на первичном dns сервере добавить записи CNAME :
```
web1		IN	CNAME	client
web2        IN  CNAME   client2
```
2.2 При этом для того чтобы запись CNAME работала обязательно должна присутствовать запить A или AAAA на которую ссылается CNAME.
2.3 После внесения изменений в зону обязательно надо увеличить значение serial для того чтобы slave сервера были в курсе внесенных изменений и запросили новую версию зоны(произошла репликация). Также для того чтобы не ждать репликации, которое происходит по истечении интервала указанного в значении refresh файла зоны. Или выполнить команду
```
rndc reload
```
или лучше (если на сервере обыслуживает несколько зон)
```
rndc reload <zone name>
```

---
2. завести еще одну зону newdns.lab, завести в ней запись www - смотрит на обоих клиентов.

2.1 Нужно cоздать файл зоны на master сервере  следующего содержания:
```
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.newdns.lab. root.newdns.lab. (
                            2		 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.newdns.lab.
                IN      NS      ns02.newdns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11
newdns.lab.	IN	A	192.168.50.15
newdns.lab.	IN	A	192.168.50.16
www		IN	CNAME	newdns.lab.
```
Краткое описание основных значений:
**$TTL** – Время актуальности записей в секундах. Можно поставить и поменьше, но это увеличит нагрузку на сервер.
**Serial** – порядковый номер изменения. При ручном редактировании файла его нужно каждый раз увеличивать для того чтобы вторичный сервер знал что зона изменилась и запрашивал ее копирование себе.
**Refresh** – время через которое вторичные сервера должны делать запрос на обновление зоны.
**Retry** – как часто должны повторять запрос на копирование зоны вторичные сервера, если главный сервер не ответил.
**Expire** – время, которое может работать вторичный сервер, если первичный перестал недоступен. По истечении этого времени вторичный сервер перестанет отвечать на запросы.

2.2 Также необходимо добавить запись о зоне в конфиги named.conf master и slave серверов. В записи должно быть имя зоны, тип , расположение файла и опции для репликации зоны. Ниже примеры для:
*Master* - 
```
	zone "newdns.lab" {
	    type master;
	    file "/var/named/client1/named.newdns.lab";
	    allow-transfer { key "zonetransfer.key"; };
	};
```
*Slave*
```
    zone "newdns.lab" {
        type slave;
        masters { 192.168.50.10 key "zonetransfer.key"; };
        file "/var/named/client1/named.newdns.lab";
```
---
3. Настроить split-dns. Клиент1 - видит обе зоны, но в зоне dns.lab только web1. Клиент2 видит только dns.lab
3.1 Данная задача была решена с помощью разных view для клиента1 и клиента2.
3.2 Сначала надо задать ACL для view вида в конфиге named.conf:
```
acl client1 { key "zonetransfer.key"; 192.168.50.15; };
```
Затем сам view внутри которого описываются зоны.
```
view client1 {
	match-clients { client1; };


	// lab's zone
	zone "dns.lab" {
		type master;
     		 file "/var/named/client1/named.dns.lab";
		 allow-transfer { key "zonetransfer.key"; };
};

	// lab's zone reverse
	zone "50.168.192.in-addr.arpa" {
	    type master;
	    file "/var/named/client1/named.dns.lab.rev";
	    allow-transfer { key "zonetransfer.key"; };
	};

	// newdns lab's zone
	zone "newdns.lab" {
	    type master;
	    file "/var/named/client1/named.newdns.lab";
	    allow-transfer { key "zonetransfer.key"; };
	};

};
```
---
4. Настроить все без выключения selinux. 
4.1. SELinux по умолчанию настроен на расположение файлов зон в папке /var/named/ c контекстом безопасности named_zone_t. Сам процесс решения проблемы был описан мной ранее в ДЗ по [SELinux](https://github.com/azatrg/OTUS-Linux-Homework/tree/master/homework-12)