# Installing on Debian Based Distributions
## Installation

This guide is a step-by-step installation guide for Debian-based distributions, it assumes a setup similar to Debian Stretch.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### Required packages

* `postgresql` (9.6+, Ubuntu 16.04 comes with 9.5, you can get a newer version from <https://www.postgresql.org/download/linux/ubuntu/>
* `postgresql-contrib` (9.6+, same situtation as above)
* `elixir` (1.7+, Debian and Ubuntu ships old versions, install from <https://elixir-lang.org/install.html#unix-and-unix-like> or use [asdf](https://github.com/asdf-vm/asdf) as the pleroma user)
* `erlang-dev`
* `erlang-tools`
* `erlang-parsetools`
* `erlang-eldap`, if you want to enable ldap authenticator
* `erlang-ssh`
* `erlang-xmerl`
* `git`
* `build-essential`

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First update the system, if not already done:

```shell
# apt update
# apt full-upgrade
```

* Install some of the above mentioned programs:

```shell
# apt install git build-essential postgresql postgresql-contrib
```

* Add a new system user for the Pleroma service:

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

### Install Elixir and Erlang

* Download and add the Erlang repository:

```shell
% wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
# dpkg -i /tmp/erlang-solutions_1.0_all.deb
```

* Install Elixir and Erlang:

```shell
# apt update
# apt install elixir erlang-dev erlang-parsetools erlang-xmerl erlang-tools erlang-ssh
```

### Install Nginx

* Install nginx, if not already done:

```shell
# apt install nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
# apt install certbot
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

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html).
