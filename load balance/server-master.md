# Config for server master

### Installation
```
# apt install postgresql-16 pgpool2 -y
```

### Edit file postgresql.conf
```
# vim /etc/postgresql/16/main/postgresql.conf

listen_addresses = '*'
port = 5432
wal_level = replica
wal_log_hints = on
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

host    replication     all             0.0.0.0/0               scram-sha-256
host    all             all             0.0.0.0/0               scram-sha-256
```

### Edit file pgpool.conf
```
# vim /etc/pgpool2/pgpool.conf

listen_addresses = '*'
port = 9999

backend_hostname0 = 'psql1'
backend_port0 = 5432
backend_weight0 = 0
backend_data_directory0 = '/var/lib/postgresql/16/main'
backend_flag0 = 'DISALLOW_TO_FAILOVER'
backend_application_name0 = 'primary'

backend_hostname1 = 'psql2'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/16/main'
backend_flag1 = 'DISALLOW_TO_FAILOVER'
backend_application_name1 = 'replica'

enable_pool_hba = on
load_balance_mode = on
sr_check_user = 'repl'
sr_check_password = ''
health_check_period = 10
health_check_timeout = 30
health_check_user = 'repl'
health_check_password = ''
```

### Create user replication
```
# su - postgres
$ createuser --replication -P rep_user
$ exit
# systemctl restart postgresql
```

### edit pool_hba
```
vim /etc/pgpool2/pool_hba.conf

host    all         repl        0.0.0.0/0        scram-sha-256
```

### create pgpoolkey for pool_hba auth
```
# su - postgres
$ echo 'some string' > ~/.pgpoolkey
$ chmod 600 ~/.pgpoolkey
$ exit
# pg_enc -m -k /var/lib/postgresql/.pgpoolkey -u repl -p
# cat /etc/pgpool2/pool_passwd
```