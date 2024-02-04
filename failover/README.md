# Configuration Failover

### installation
```
apt install postgresql-16-pgpool2 postgresql-16-pg-failover-slots sudo pgpool2 -y
```

### Create archive dir for archive mode on all server
```
# mkdir -p /var/lib/postgresql/16/archive
# chown -R postgres:postgres /var/lib/postgresql/16/archive
```

### Edit file posgresql.conf on server master
```
# vim /etc/posgresql/13/main/postgresql.conf

listen_addresses = '*'
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/16/archive/%f'
wal_level = replica
hot_standby = on
wal_log_hints = on
```

### create users on server master
![users for auth reps and health check](../img/users.png)
```
# su - postgres
$ psql
=# SET password_encryption = 'scram-sha-256';
=# CREATE ROLE pgpool WITH LOGIN;
=# CREATE ROLE repl WITH REPLICATION LOGIN;
=# \password pgpool
=# \password repl
=# \password postgres
=# GRANT pg_monitor TO pgpool;
```

### edit file pg_hba.conf on all server
```
# vim /etc/postgresql/13/main/pg_hba.conf
//tambahkan command dibawah pada bagian paling bawah
host    all             all             0.0.0.0/0                 scram-sha-256
host    replication     all             0.0.0.0/0                 scram-sha-256
```

### Create ssh pubkey on all server

Untuk menggunakan automated failover dan recovery kita perlu mengallow ssh pubkey.
pertama set password untuk user postgres untuk *semua server*
```
# passwd postgres
```

create pubkey pada *semua server*
```
# ssh-keygen -t rsa
# ssh-copy-id postgres@server1
# ssh-copy-id postgres@server2
# ssh-copy-id postgres@server3

# su - postgres
$ ssh-keygen -t rsa
$ ssh-copy-id postgres@server1
$ ssh-copy-id postgres@server2
$ ssh-copy-id postgres@server3
```
### create pgpass file on all server
.pgpass file ini digunakan untuk auth repl user tanpa harus memasukkan password lagi untuk streaming replication dan online recovery. Jadi kita tidak perlu lagi specified password pada postgresql.conf
```
# su - postgres
$ vim /var/lib/postgresql/.pgpass

server1:5432:replication:repl:<repl user password>
server2:5432:replication:repl:<repl user password>
server1:5432:postgres:postgres:<postgres user password>
server2:5432:postgres:postgres:<postgres user password>
$ chmod 600 /var/lib/postgresql/.pgpass
```

### Create pgpool_node_id on all server

server master/primary
```
# echo "0" > /etc/pgpool2/pgpool_node_id
```

server slave/replica
```
# echo "1" > /etc/pgpool2/pgpool_node_id
```

### edit pgpool.conf on all server

config listen address, port, streaming replication check and health check
```
# vim /etc/pgpool2/pgpool.conf

listen_addresses = '*'
pcp_listen_addresses = '*'
port = 9999
pcp_port = 9898
sr_check_user = 'pgpool'
sr_check_password = ''
health_check_period = 5
health_check_timeout = 30
health_check_user = 'pgpool'
health_check_password = ''
health_check_max_retries = 3


//configure backend setting

backend_hostname0 = 'psql1'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/16/main'
backend_flag0 = 'ALLOW_TO_FAILOVER'
backend_application_name0 = 'primary'

backend_hostname1 = 'psql2'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/16/main'
backend_flag1 = 'ALLOW_TO_FAILOVER'
backend_application_name1 = 'replica'

//failover config

failover_command = '/etc/pgpool-II/failover.sh %d %h %p %D %m %H %M %P %r %R %N %S'
follow_primary_command = '/etc/pgpool-II/follow_primary.sh %d %h %p %D %m %H %M %P %r %R'


//recovery config just for primary server 
recovery_user = 'postgres'
recovery_password = ''
recovery_1st_stage_command = 'recovery_1st_stage'

//enable pool hba
enable_pool_hba = on

//enable watchdog
use_watchdog = on
if_up_cmd = '/usr/bin/sudo /sbin/ip addr add $_IP_$/24 dev enp0s8 label enp0s8:0'
if_down_cmd = '/usr/bin/sudo /sbin/ip addr del $_IP_$/24 dev enp0s8'
arping_cmd = '/usr/bin/sudo /usr/sbin/arping -U $_IP_$ -w 1 -I enp0s8'
if_cmd_path = '/sbin'
arping_path = '/usr/sbin'
hostname0 = 'psql1'
wd_port0 = 9000
pgpool_port0 = 9999
hostname1 = 'psql2'
wd_port1 = 9000
pgpool_port1 = 9999

wd_lifecheck_method = 'heartbeat'
wd_interval = 10
wd_heartbeat_keepalive = 2
wd_heartbeat_deadtime = 30
wd_escalation_command = '/etc/pgpool2/escalation.sh'


//logging
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/pgpool_log'
log_filename = 'pgpool-%Y-%m-%d_%H%M%S.log'
log_truncate_on_rotation = on
log_rotation_age = 1d
log_rotation_size = 10MB

```

### Create and chown failover.sh and follow_primary.sh on all server
copy file failover.sh dan follow_primary.sh pada directory /etc/pgpool2/
chown file failover.sh dan follow_primary.sh
```
chown postgres:postgres /etc/pgpool2/{failover.sh,follow_primary.sh}
```

### Create password for pcp on all server
```
# echo 'pgpool:'`pg_md5 <pgpool user password> passowrd` >> /etc/pgpool2/pcp.conf
# su - postgres
$ echo 'localhost:9898:pgpool:<pgpool user password>' > ~/.pcppass
$ chmod 600 ~/.pcpass
```

### create recovery_1st_stage and pgpool_remote_start on server master
copy file recovery_1st_stage and pgpool_remote_start
chown file
```
chown postgres:postgres /var/lib/postgresql/16/main/{recovery_1st_stage,pgpool_remote_start}
```

### Enable recovery extension on server master
```
# su - postgres
$ psql template1 -c "CREATE EXTENSION pgpool_recovery"
```

### Client auth on all server
edit file pool_hba.conf

```
vim /etc/pgpool2/pool_hba.conf

host    all         pgpool           0.0.0.0/0          scram-sha-256
host    all         postgres         0.0.0.0/0          scram-sha-256
```

### create pgpool key on all server
```
# su - postgres
$ echo 'some string' > ~/.pgpoolkey
$ chmod 600 ~/.pgpoolkey
$ exit
# pg_enc -m -k /var/lib/postgresql/.pgpoolkey -u pgpool -p
# pg_enc -m -k /var/lib/postgresql/.pgpoolkey -u postgres -p
# cat /etc/pgpool2/pool_passwd
```

### create file escalations.sh on all server
copy file escalation.sh and chown
```
# chown postgres:postgres /etc/pgpool2/escalation.sh
```

### create directory logging on al server
```
# mkdir /var/log/pgpool_log/
# chown postgres:postgres /var/log/pgpool_log/
```