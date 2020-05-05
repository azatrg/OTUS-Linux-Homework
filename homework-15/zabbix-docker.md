
Postgres

'''
docker run -d --name zabbix-postgres --network zabbix-net -v /var/lib/zabbix/timezone:/etc/timezone \
 -v /var/lib/zabbix/localtime:/etc/localtime -e POSTGRES_PASSWORD=zabbix \ 
  -e POSTGRES_USER=zabbix postgres:alpine
'''

Zabbix server

'''
docker run --name zabbix-server --network zabbix-net -v /var/lib/zabbix/alertscripts:/usr/lib/zabbix/alertscripts \ 
-v /var/lib/zabbix/timezone:/etc/timezone -v /var/lib/zabbix/localtime:/etc/localtime -p 10051:10051 \
 -e DB_SERVER_HOST="zabbix-postgres" -e POSTGRES_USER="zabbix" -e POSTGRES_PASSWORD="zabbix" \ 
  -d zabbix/zabbix-server-pgsql:alpine-latest
'''



Zabbix web-server

'''
docker run --name zabbix-web -p 80:8080 -p 443:443 --network zabbix-net -e DB_SERVER_HOST="zabbix-postgres" \
 -v /var/lib/zabbix/timezone:/etc/timezone -v /var/lib/zabbix/localtime:/etc/localtime -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" -e ZBX_SERVER_HOST="zabbix-server" -e PHP_TZ="Europe/Moscow" \
   -d zabbix/zabbix-web-nginx-pgsql:alpine-latest
'''