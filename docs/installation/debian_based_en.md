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
# apt autoremove
# reboot
```

* Install some of the above mentioned programs:

```shell
# apt install git build-essential
```

* Add a new system user for the Pleroma service:

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

### Install PostgreSQL

Following tutorial is for Ubuntu 16. For other platforms, see [PostgreSQL's official document](https://www.postgresql.org/download/linux/ubuntu/).

```shell
# nano /etc/apt/sources.list.d/pgdg.list
```

Write following code into the `pgdg.list`.

```
deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main
```

```shell
% wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
# apt update
# apt install postgresql postgresql-contrib
```

Check PostgreSQL's port number and version.

```shell
postgres $ psql -p 5432 -c 'SELECT version()'
```

If some versions of PostgreSQL are installed in your system, try sequential port numbers 5432, 5433, ..., while you get the version you want.

### Install Elixir and Erlang

* Download and add the Erlang repository:

```shell
% wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
# dpkg -i /tmp/erlang-solutions_1.0_all.deb
```

* Install Elixir and Erlang:

```shell
# apt update
# apt install elixir erlang-dev erlang-tools erlang-parsetools erlang-eldap erlang-xmerl erlang-ssh
```

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html). After do that, go back to this document.

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
# systemctl stop nginx
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
# systemctl start nginx
--standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

---

* Copy the example nginx configuration and activate it:

```shell
# cp ~pleroma/pleroma/installation/pleroma.nginx /etc/nginx/sites-available
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

#### Workarounds for nginx

You can watch the nginx's log by ``# systemctl status nginx`` or ``# journalctl -u nginx`` commands.

If your nginx does not work, and claims following message, this is [nginx's known bug](https://bugs.launchpad.net/ubuntu/+source/nginx/+bug/1581864).

```
systemd[1]: nginx.service: Failed to read PID from file /run/nginx.pid: Invalid argument
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
nginx[1431]: nginx: [emerg] Unknown curve name "X25519:prime256v1:secp384r1:secp521r1" (SSL:)
```

Edit `/etc/nginx/sites-available/pleroma.nginx` and just comment out `ssl_ecdh_curve X25519:prime256v1:secp384r1:secp521r1;`.

#### Other webserver/proxies

You can find example configurations for them in `/var/lib/pleroma/installation/`.

