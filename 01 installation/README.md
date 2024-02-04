# Installation postgresql-16

### Import repo postgresql and Install postgresql
```
apt install gnupg
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get -y install postgresql
```

### Setup environment variable
```
su - postgres
echo echo PATH=/usr/lib/postgresql/16/bin:$PATH >> ~/.bashrc
```