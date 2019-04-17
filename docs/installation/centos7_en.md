# Installing on CentOS 7
## Installation

This guide is a step-by-step installation guide for CentOS 7. It also assumes that you have administrative rights, either as root or a user with [sudo permissions](https://www.digitalocean.com/community/tutorials/how-to-create-a-sudo-user-on-centos-quickstart). If you want to run this guide with root, ignore the `sudo` at the beginning of the lines, unless it calls a user like `sudo -Hu pleroma`; in this case, use `su <username> -s $SHELL -c 'command'` instead.

### Required packages

* `postgresql` (9,6+, CentOS 7 comes with 9.2, we will install version 11 in this guide)
* `elixir` (1.5+)
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
sudo yum update
```

* Install some of the above mentioned programs:

```shell
sudo yum install wget git unzip
```

* Install development tools:

```shell
sudo yum group install "Development Tools"
```

* Add a new system user for the Pleroma service:

```shell
sudo useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

**Note**: To execute a single command as the Pleroma system user, use `sudo -Hu pleroma command`. You can also switch to a shell by using `sudo -Hu pleroma $SHELL`. If you don’t have and want `sudo` on your system, you can use `su` as root user (UID 0) for a single command by using `su -l pleroma -s $SHELL -c 'command'` and `su -l pleroma -s $SHELL` for starting a shell.

### Install Elixir and Erlang

* Add the EPEL repo:

```shell
sudo yum install epel-release
sudo yum -y update
```

* Install Erlang repository:

```shell
wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
sudo rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
```

* Install Erlang:

```shell
sudo yum install erlang erlang-parsetools erlang-xmerl
```

* Download [latest Elixir release from Github](https://github.com/elixir-lang/elixir/releases/tag/v1.8.1) (Example for the newest version at the time when this manual was written)

```shell
wget -P /tmp/ https://github.com/elixir-lang/elixir/releases/download/v1.8.1/Precompiled.zip
```

* Create folder where you want to install Elixir, we’ll use:

```shell
sudo mkdir -p /opt/elixir
```

* Unzip downloaded file there:

```shell
sudo unzip /tmp/Precompiled.zip -d /opt/elixir
```

* Create symlinks for the pre-compiled binaries:

```shell
for e in elixir elixirc iex mix; do sudo ln -s /opt/elixir/bin/${e} /usr/local/bin/${e}; done
```

### Install PostgreSQL

* Add the Postgresql repository:

```shell
sudo yum install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
```

* Install the Postgresql server:

```shell
sudo yum install postgresql11-server postgresql11-contrib
```

* Initialize database:

```shell
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
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
sudo systemctl enable --now postgresql-11.service
```

#### Nginx

* Install nginx, if not already done:

```shell
sudo yum install nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
sudo yum install certbot-nginx
```

and then set it up:

```shell
sudo mkdir -p /var/lib/letsencrypt/
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

---

* Copy the example nginx configuration to the nginx folder

```shell
sudo cp /opt/pleroma/installation/pleroma.nginx /etc/nginx/conf.d/pleroma.conf
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
sudo systemctl enable --now nginx
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### Other webserver/proxies

You can find example configurations for them in the `installation` directory of pleroma.

#### Systemd service

* Copy example service file

```shell
sudo cp /opt/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* Edit the service file and make sure that all paths fit your installation
* Enable and start `pleroma.service`:

```shell
sudo systemctl enable --now pleroma.service
```

### Install and Configure Pleroma
Log into to pleroma user, with `sudo -Hu pleroma $SHELL` or `su -l pleroma -s $SHELL` if you do not have `sudo`. And follow [installation/generic_pleroma_en.md](Generic Pleroma Installation).
