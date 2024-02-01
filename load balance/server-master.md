# Config for server master

### Installation
```
# apt install postgresql-13 pgpool2 -y
```

### Edit file postgresql.conf
```
# vim /etc/postgresql/13/main/postgresql.conf

listen_addresses = '*'
port = 5432
wal_level = replica
synchronous_commit = remote_apply
wal_log_hints = on
synchronous_standby_names = '*'
```

### Edit file pg_hba.conf
```
# vim /etc/postgresql/13/main/pg_hba.conf

host    replication     rep_user        172.23.3.11/32          md5
host    replication     rep_user        172.23.3.12/32          md5
host    all             rep_user        0.0.0.0/0               md5
```

### Edit file pgpool.conf
```
# vim /etc/pgpool2/pgpool.conf

listen_addresses = '*'
port = 5433

backend_hostname0 = 'localhost'
backend_port0 = 5432
backend_weight0 = 0
backend_data_directory0 = '/var/lib/postgresql/13/main'
backend_flag0 = 'DISALLOW_TO_FAILOVER'
backend_application_name0 = 'primary'

backend_hostname1 = '172.23.3.12'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/13/main'
backend_flag1 = 'DISALLOW_TO_FAILOVER'
backend_application_name1 = 'replica'

load_balance_mode = on
master_slave_mode = on
sr_check_user = 'rep_user'
sr_check_password = 'admin123'
health_check_user = 'rep_user'
health_check_password = 'admin123'
```

### Create user replication
```
# su - postgres
$ createuser --replication -P rep_user
$ exit
# systemctl restart postgresql
```