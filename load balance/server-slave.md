# Config for server slave

### Installation
```
# apt install postgresql-13
```

### Edit file postgresql.conf
```
# vim /etc/postgresql/13/main/postgresql.conf
listen_addresses = '*'
port = 5432
hot_standby = on
```

### Stop service postgresql and delete data file postgresql
```
# systemctl stop postgresql
# rm -rf /var/lib/postgresql/13/main/*
```

### Backup database from master
```
# su - postgres
$ pg_basebackup -R -h <ip server master> -U rep_user -D /var/lib/postgresql/13/main -P
```

### Edit file postgresql.auto.conf

tambahkan parameter application_name pada baris terakhir
```
# vim /var/lib/postgresql/13/main/postgresql.auto.conf
primary_conninfo = 'user=rep_user password=password host=<ip server master> port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any *application_name=server-slave*'
```