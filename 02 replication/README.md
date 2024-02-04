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
