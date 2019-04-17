# Installing on Alpine Linux
## Installation

This guide is a step-by-step installation guide for Alpine Linux. It also assumes that you have administrative rights, either as root or a user with [sudo permissions](https://www.linode.com/docs/tools-reference/custom-kernels-distros/install-alpine-linux-on-your-linode/#configuration). If you want to run this guide with root, ignore the `sudo` at the beginning of the lines, unless it calls a user like `sudo -Hu pleroma`; in this case, use `su -l <username> -s $SHELL -c 'command'` instead.

### Required packages

* `postgresql`
* `postgresql-contrib`
* `elixir`
* `erlang`
* `erlang-parsetools`
* `erlang-xmerl`
* `erlang-eldap`: *optionnal*, used if you want LDAP
* `git`
* `build-base`

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First make sure to have the community repository enabled:

```shell
echo "https://nl.alpinelinux.org/alpine/latest-stable/community" | sudo tee -a /etc/apk/repository
```

* Then update the system, if not already done:

```shell
sudo apk update
sudo apk upgrade
```

* Install some tools, which are needed later:

```shell
sudo apk add git build-base
```

* Add a new system user for the Pleroma service:

```shell
sudo adduser -S -s /bin/false -h /opt/pleroma -H pleroma
```

**Note**: To execute a single command as the Pleroma system user, use `sudo -Hu pleroma command`. You can also switch to a shell by using `sudo -Hu pleroma $SHELL`. If you don’t have and want `sudo` on your system, you can use `su` as root user (UID 0) for a single command by using `su -l pleroma -s $SHELL -c 'command'` and `su -l pleroma -s $SHELL` for starting a shell.

### Install Elixir and Erlang

* Install Erlang and Elixir:

```shell
sudo apk add erlang erlang-runtime-tools erlang-xmerl elixir
```

* Install `erlang-eldap` if you want to enable ldap authenticator

```shell
sudo apk add erlang-eldap
```
### Install PostgreSQL

* Install Postgresql server:

```shell
sudo apk add postgresql postgresql-contrib
```

* Initialize database:

```shell
sudo service postgresql start
```

* Enable and start postgresql server:

```shell
sudo rc-update add postgresql
```

### Finalize installation

If you want to open your newly installed instance to the world, you should run nginx or some other webserver/proxy in front of Pleroma and you should consider to create an OpenRC service file for Pleroma.

#### Nginx

* Install nginx, if not already done:

```shell
sudo apk add nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
sudo apk add certbot
```

and then set it up:

```shell
sudo mkdir -p /var/lib/letsencrypt/
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

* Copy the example nginx configuration to the nginx folder

```shell
sudo cp ~pleroma/pleroma/installation/pleroma.nginx /etc/nginx/conf.d/pleroma.conf
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
sudo rc-update add nginx
sudo service nginx start
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### OpenRC service

* Copy example service file:

```shell
sudo cp ~pleroma/pleroma/installation/init.d/pleroma /etc/init.d/pleroma
```

* Make sure to start it during the boot

```shell
sudo rc-update add pleroma
```

### Install and Configure Pleroma
Log into to pleroma user, with `sudo -Hu pleroma $SHELL` or `su -l pleroma -s $SHELL` if you do not have `sudo`. And follow [installation/generic_pleroma_en.md](Generic Pleroma Installation).
