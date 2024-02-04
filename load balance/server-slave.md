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
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/16/archive/%f'
```

### create archive dir
```
# mkdir -p /var/lib/postgresql/16/archive
# chown -R postgres:postgres /var/lib/postgresql/16/archive
```

### Edit file pg_hba.conf
```
# vim /etc/postgresql/16/main/pg_hba.conf

host    all             all             0.0.0.0/0               scram-sha-256
```

### Stop service postgresql and delete data file postgresql
```
# systemctl stop postgresql
# rm -rf /var/lib/postgresql/16/main/*
```

### Backup database from master
```
# su - postgres
$ pg_basebackup -R -h <ip server master> -U repl -D /var/lib/postgresql/16/main -P
```

### Edit file postgresql.auto.conf

tambahkan parameter application_name pada baris terakhir
```
# vim /var/lib/postgresql/16/main/postgresql.auto.conf

primary_conninfo = 'user=rep_user password=password host=<ip server master> port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any application_name=server-slave'
```