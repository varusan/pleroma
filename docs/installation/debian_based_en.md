# Installing on Debian Based Distributions
## Installation

This guide will assume you are on Debian Stretch. This guide should also work with Ubuntu 16.04 and 18.04. It also assumes that you have administrative rights, either as root or a user with [sudo permissions](https://www.digitalocean.com/community/tutorials/how-to-add-delete-and-grant-sudo-privileges-to-users-on-a-debian-vps). If you want to run this guide with root, ignore the `sudo` at the beginning of the lines, unless it calls a user like `sudo -Hu pleroma`; in this case, use `su <username> -s $SHELL -c 'command'` instead.

### Required packages

* `postgresql` (9.6+, Ubuntu 16.04 comes with 9.5, you can get a newer version from [here](https://www.postgresql.org/download/linux/ubuntu/))
* `postgresql-contrib` (9.6+, same situtation as above)
* `elixir` (1.5+, [install from here, Debian and Ubuntu ship older versions](https://elixir-lang.org/install.html#unix-and-unix-like) or use [asdf](https://github.com/asdf-vm/asdf) as the pleroma user)
* `erlang-dev`
* `erlang-tools`
* `erlang-parsetools`
* `erlang-eldap`, if you want to enable ldap authenticator
* `erlang-xmerl`
* `git`
* `build-essential`

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First update the system, if not already done:

```shell
sudo apt update
sudo apt full-upgrade
```

* Install some of the above mentioned programs:

```shell
sudo apt install git build-essential postgresql postgresql-contrib
```

* Add a new system user for the Pleroma service:

```shell
sudo useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

**Note**: To execute a single command as the Pleroma system user, use `sudo -Hu pleroma command`. You can also switch to a shell by using `sudo -Hu pleroma $SHELL`. If you don’t have and want `sudo` on your system, you can use `su` as root user (UID 0) for a single command by using `su -l pleroma -s $SHELL -c 'command'` and `su -l pleroma -s $SHELL` for starting a shell.

### Install Elixir and Erlang

* Download and add the Erlang repository:

```shell
wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i /tmp/erlang-solutions_1.0_all.deb
```

* Install Elixir and Erlang:

```shell
sudo apt update
sudo apt install elixir erlang-dev erlang-parsetools erlang-xmerl erlang-tools
```

### Install Nginx

* Install nginx, if not already done:

```shell
sudo apt install nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
sudo apt install certbot
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

### Systemd service

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
