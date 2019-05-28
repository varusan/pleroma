# Installing on CentOS 7
## Installation

This guide is a step-by-step installation guide for CentOS 7.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### Required packages

* `postgresql` (9,6+, CentOS 7 comes with 9.2, we will install version 11 in this guide)
* `elixir` (1.7+)
* `erlang`
* `erlang-parsetools`
* `erlang-xmerl`
* `git`
* Development Tools

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First update the system, if not already done:

```shell
# yum update
# reboot
```

* Install some of the above mentioned programs:

```shell
# yum install wget git unzip
```

* Install development tools:

```shell
# yum group install "Development Tools"
```

* Add a new system user for the Pleroma service:

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

### Install Elixir and Erlang

* Add the EPEL repo:

```shell
# yum install epel-release
# yum -y update
```

* Install Erlang repository:

```shell
% wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
# rpm -Uvh /tmp/erlang-solutions-1.0-1.noarch.rpm
```

* Install Erlang:

```shell
# yum install erlang erlang-parsetools erlang-xmerl
```

* Download [latest Elixir release from Github](https://github.com/elixir-lang/elixir/releases/tag/v1.8.2) (Example for the newest version at the time when this manual was written)

```shell
% wget -P /tmp/ https://github.com/elixir-lang/elixir/releases/download/v1.8.2/Precompiled.zip
```

* Create folder where you want to install Elixir, we’ll use:

```shell
# mkdir -p /opt/elixir
```

* Unzip downloaded file there:

```shell
# unzip /tmp/Precompiled.zip -d /opt/elixir
```

* Create symlinks for the pre-compiled binaries:

```shell
# for e in elixir elixirc iex mix; do sudo ln -s /opt/elixir/bin/${e} /usr/local/bin/${e}; done
```

### Install PostgreSQL

* Add the Postgresql repository:

```shell
# yum install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
```

* Install the Postgresql server:

```shell
# yum install postgresql11-server postgresql11-contrib
```

* Initialize database:

```shell
# /usr/pgsql-11/bin/postgresql-11-setup initdb
```

* Open configuration file `/var/lib/pgsql/11/data/pg_hba.conf` and change the following lines from:

```plain
# IPv4 local connections:
host    all             all             127.0.0.1/32            ident
# IPv6 local connections:
host    all             all             ::1/128                 ident
```

to

```plain
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
```

* Enable and start postgresql server:

```shell
# systemctl enable --now postgresql-11.service
```

Check PostgreSQL's port number and version.

```shell
postgres $ psql -p 5432 -c 'SELECT version()'
```

If some versions of PostgreSQL are installed in your system, try sequential port numbers 5432, 5433, ..., while you get the version you want.

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html). After do that, go back to this document.

#### Nginx

* Install nginx, if not already done:

```shell
# yum install nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
# yum install certbot-nginx
```

and then set it up:

```shell
# mkdir -p /var/lib/letsencrypt/
# systemctl stop nginx
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
# systemctl start nginx
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

---

* Copy the example nginx configuration to the nginx folder

```shell
# cp /var/lib/pleroma/pleroma/installation/pleroma.nginx /etc/nginx/conf.d/pleroma.conf
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
# systemctl enable --now nginx
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
# certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### Workarounds for nginx

You can watch the nginx's log by ``# systemctl status nginx`` or ``# journalctl -u nginx`` commands.

If your nginx does not work, and claims following message, this is [nginx's known bug](https://bugs.launchpad.net/ubuntu/+source/nginx/+bug/1581864).

```
systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
```

Following workaround may helps you.

```shell
# mkdir /etc/systemd/system/nginx.service.d
# printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf
# systemctl daemon-reload
# systemctl restart nginx
```

If your nginx still does not work, and claims following message, your nginx dose not know some of the modern cryptographic algorithms.

```
nginx[5982]: nginx: [emerg] SSL_CTX_set1_curves_list("X25519:prime256v1:secp384r1:secp521r1") failed (SSL:)
```

Edit `/etc/nginx/sites-available/pleroma.nginx` and just comment out `ssl_ecdh_curve X25519:prime256v1:secp384r1:secp521r1;`.

#### Other webserver/proxies

You can find example configurations for them in the `installation` directory of pleroma.

