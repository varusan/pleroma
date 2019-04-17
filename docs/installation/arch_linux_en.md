# Installing on Arch Linux
## Installation

This guide will assume that you have administrative rights, either as root or a user with [sudo permissions](https://wiki.archlinux.org/index.php/Sudo). If you want to run this guide with root, ignore the `sudo` at the beginning of the lines, unless it calls a user like `sudo -Hu pleroma`; in this case, use `su <username> -s $SHELL -c 'command'` instead.

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
sudo pacman -Syu
```

* Install some of the above mentioned programs:

```shell
sudo pacman -S git base-devel elixir
```

* Add a new system user for the Pleroma service:

```shell
sudo useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

**Note**: To execute a single command as the Pleroma system user, use `sudo -Hu pleroma command`. You can also switch to a shell by using `sudo -Hu pleroma $SHELL`. If you don’t have and want `sudo` on your system, you can use `su` as root user (UID 0) for a single command by using `su -l pleroma -s $SHELL -c 'command'` and `su -l pleroma -s $SHELL` for starting a shell.

### Install PostgreSQL

[Arch Wiki article](https://wiki.archlinux.org/index.php/PostgreSQL)

* Install the `postgresql` package:

```shell
sudo pacman -S postgresql
```

* Initialize the database cluster:

```shell
sudo -iu postgres initdb -D /var/lib/postgres/data
```

* Start and enable the `postgresql.service`

```shell
sudo systemctl enable --now postgresql.service
```

#### Nginx

* Install nginx, if not already done:

```shell
sudo pacman -S nginx
```

* Create directories for available and enabled sites:

```shell
sudo mkdir -p /etc/nginx/sites-{available,enabled}
```

* Append the following line at the end of the `http` block in `/etc/nginx/nginx.conf`:

```Nginx
include sites-enabled/*;
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
sudo pacman -S certbot certbot-nginx
```

and then set it up:

```shell
sudo mkdir -p /var/lib/letsencrypt/
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

---

* Copy the example nginx configuration and activate it:

```shell
sudo cp /opt/pleroma/installation/pleroma.nginx /etc/nginx/sites-available/pleroma.nginx
sudo ln -s /etc/nginx/sites-available/pleroma.nginx /etc/nginx/sites-enabled/pleroma.nginx
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
sudo systemctl enable --now nginx.service
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
sudo certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### Other webserver/proxies

You can find example configurations for them in `/opt/pleroma/installation/`.

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
