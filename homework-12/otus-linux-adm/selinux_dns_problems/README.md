#### SELinux: проблема с удаленным обновлением зоны DNS

Инженер настроил следующую схему:

- ns01 - DNS-сервер (192.168.50.10);
- client - клиентская рабочая станция (192.168.50.15).

При попытке удаленно (с рабочей станции) внести изменения в зону ddns.lab происходит следующее:
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
>
```
Инженер перепроверил содержимое конфигурационных файлов и, убедившись, что с ними всё в порядке, предположил, что данная ошибка связана с SELinux.

В данной работе предлагается разобраться с возникшей ситуацией.


#### Задание

- Выяснить причину неработоспособности механизма обновления зоны.
- Предложить решение (или решения) для данной проблемы.
- Выбрать одно из решений для реализации, предварительно обосновав выбор.
- Реализовать выбранное решение и продемонстрировать его работоспособность.


#### Формат

- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них.
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

#### Исправление

Изменил распложение файлов зон c /etc/named/ на /var/named/

```
diff files/ns01/named.conf files/ns01/named.conf_old
70c70
<         file "/var/named/named.dns.lab.view1";
---
>         file "/etc/named/named.dns.lab.view1";
78c78
<         file "/var/named/dynamic/named.ddns.lab.view1";
---
>         file "/etc/named/dynamic/named.ddns.lab.view1";
85c85
<         file "/var/named/named.newdns.lab";
---
>         file "/etc/named/named.newdns.lab";
92c92
<         file "/var/named/named.50.168.192.rev";
---
>         file "/etc/named/named.50.168.192.rev";
114c114
<         file "/var/named/data/named.dns.lab";
---
>         file "/etc/named/named.dns.lab";
122c122
<         file "/var/named/dynamic/named.ddns.lab";
---
>         file "/etc/named/dynamic/named.ddns.lab";
129c129
<         file "/var/named/data/named.newdns.lab";
---
>         file "/etc/named/named.newdns.lab";
136c136
<         file "/var/named/data/named.50.168.192.rev";
---
>         file "/etc/named/named.50.168.192.rev";

```

Скопировать себе измененный стенд и развернуть. Изменения в зону проходят без ошибок.