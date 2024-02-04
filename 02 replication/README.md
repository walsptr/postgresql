# Config Replication

## Config Streaming Replication Asynchronous
### Config server primary

Edit file postgresql.conf
```
vim /etc/postgresql/16/main/postgresql.conf

listen_address = '*'
port = 5432
wal_level = replica
cluster_name = 'psql1'
```

Edit file pg_hba.conf for auth user. tambahkan baris perintah ini pada baris paling bawah
```
vim /etc/postgresql/16/main/pg_hba.conf

host    replication     repl            172.23.0.0/20           scram-sha-256
host    all             repl            172.23.0.0/20           scram-sha-256
```

Create user replication
```
su - postgres
createuser --replication -P repl
```

restart service postgresql
```
systemctl restart postgresql
```

### Config server standby

Stop service postgresql
```
systemctl stop postgresql
```

remove data directory postgresql
```
rm -rf /var/lib/postgresql/16/main/*
```

jalankan online backup dari server primary --> server standby
```
pg_basebackup -R -h <hostname/ip server primary> -D /var/lib/postgresql/16/main -p 5432 -U repl -P
```

Edit file postgresql.conf
```
vim /etc/postgresql/16/main/postgresql.conf

listen_addresses = '*' 
port = 5432
wal_level = replica
hot_standby = on
primary_conninfo = 'user=<user repl> host=<ip server primary> password=<password user repl> port=5432 application_name=psql2'
cluster_name = 'psql2'
```

Jalankan kembali service postgresql
```
systemctl start postgresql
```

### Testing streaming replication asynchronous

Check status replication
```
su - postgres
psql

# expanded display
\x

# show status replication on primary
select * from pg_stat_replication;

# Show status replication on replica
select * from pg_stat_wal_receiver;

# Insert some data on primary server
create table tb_data(id int primary key, name varchar);
insert into tb_data values(generate_series(1,10),'data'||generate_series(1,10)); 

# check data on all server
select * from tb_data;
```

## Config Streaming Replication synchronous
### Config on server primary

create new database cluster
```
su - postgres
initdb -D primary_sync
```

Start service postgresql using pg_ctl
```
pg_ctl start -D /var/lib/postgresql/primary_sync -l /var/log/postgresql/primary_sync.log
```

Edit file postgresql.conf
```
vim /var/lib/postgresql/primary_sync/postgresql.conf

listen_address = '*'
port = 5433
wal_level = replica
cluster_name = 'psql-sync1'
synchronous_commit = on
synchronous_standby_names = '*'
```

Edit file pg_hba.conf for auth user. tambahkan baris perintah ini pada baris paling bawah
```
vim /var/lib/postgresql/primary_sync/pg_hba.conf

host    replication     repl            172.23.0.0/20           scram-sha-256
host    all             repl            172.23.0.0/20           scram-sha-256
```

Create user replication
```
su - postgres
createuser --replication -P repl -p 5433
```

Restart service postgresql using pg_ctl
```
pg_ctl restart -D /var/lib/postgresql/primary_sync -l /var/log/postgresql/primary_sync.log
```

### Config on server standby

Copy server primary --> server standby using onling backup
```
su - postgres
pg_basebackup -R -h <hostname/ip server primary> -U repl --port 5433 -D standby_sync -P
```

Edit file postgresql.conf
```
vim /var/lib/postgresql/standby_sync/postgresql.conf

listen_address = '*'
port = 5433
wal_level = replica

primary_conninfo = 'user=<user repl> host=<ip server primary> password=<password user repl> port=5433 application_name=psql-sync2'
cluster_name = 'psql-sync2'

synchronous_commit = on
synchronous_standby_names = '*'
```

Start service postgresql using pg_ctl
```
pg_ctl start -D /var/lib/postgresql/standby_sync -l /var/log/postgresql/standby_sync.log
```

### Testing streaming replication asynchronous

Check status replication
```
su - postgres
psql -p 5433

# expanded display
\x

# show status replication on primary
select * from pg_stat_replication;

# Show status replication on replica
select * from pg_stat_wal_receiver;

# Insert some data on primary server
create table tb_data(id int primary key, name varchar);
insert into tb_data values(generate_series(1,10),'data'||generate_series(1,10)); 

# check data on all server
select * from tb_data;
```