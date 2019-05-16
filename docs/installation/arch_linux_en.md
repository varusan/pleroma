# Installing on Arch Linux
## Installation

This guide is a step-by-step installation guide for Arch Linux.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### Required packages

* `postgresql`
* `elixir`
* `git`
* `base-devel`

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First update the system, if not already done:

```shell
# pacman -Syu
```

* Install some of the above mentioned programs:

```shell
# pacman -S git base-devel elixir
```

* Add a new system user for the Pleroma service:

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

### Install PostgreSQL

[Arch Wiki article](https://wiki.archlinux.org/index.php/PostgreSQL)

* Install the `postgresql` package:

```shell
# pacman -S postgresql
```

* Initialize the database cluster:

```shell
postgres $ initdb -D /var/lib/postgres/data
```

* Start and enable the `postgresql.service`

```shell
# systemctl enable --now postgresql.service
```

#### Nginx

* Install nginx, if not already done:

```shell
# pacman -S nginx
```

* Create directories for available and enabled sites:

```shell
# mkdir -p /etc/nginx/sites-{available,enabled}
```

* Append the following line at the end of the `http` block in `/etc/nginx/nginx.conf`:

```Nginx
include sites-enabled/*;
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
# pacman -S certbot certbot-nginx
```

and then set it up:

```shell
# mkdir -p /var/lib/letsencrypt/
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

---

* Copy the example nginx configuration and activate it:

```shell
# cp /opt/pleroma/installation/pleroma.nginx /etc/nginx/sites-available/pleroma.nginx
# ln -s /etc/nginx/sites-available/pleroma.nginx /etc/nginx/sites-enabled/pleroma.nginx
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
# systemctl enable --now nginx.service
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
# certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### Other webserver/proxies

You can find example configurations for them in `/opt/pleroma/installation/`.

#### Systemd service

* Copy example service file

```shell
# cp /opt/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* Edit the service file and make sure that all paths fit your installation
* Enable and start `pleroma.service`:

```shell
# systemctl enable --now pleroma.service
```

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html).
