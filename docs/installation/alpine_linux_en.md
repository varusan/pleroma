# Installing on Alpine Linux
## Installation

This guide is a step-by-step installation guide for Alpine Linux.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### Required packages
* `build-base`
* `elixir`
* `erlang`
* `erlang-eldap`: *optionnal*, used if you want LDAP
* `erlang-parsetools`
* `erlang-xmerl`
* `git`
* `postgresql`
* `postgresql-contrib`

#### Optional packages used in this guide

* `nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `certbot` (or any other ACME client for Let’s Encrypt certificates)

### Prepare the system

* First make sure to have the community repository enabled:

FIXME: Verify that tee(1) is in Alpine’s base, check if there is a mirror-agnostic way to add community repo
```shell
# echo "https://nl.alpinelinux.org/alpine/latest-stable/community" | tee -a /etc/apk/repository
```

* Then update the system, if not already done:

```shell
# apk update
# apk upgrade
```

* Install some tools, which are needed later:

```shell
# apk add git build-base
```

* Add a new system user for the Pleroma service:

```shell
# adduser -S -s /bin/false -h /opt/pleroma -H pleroma
```

### Install Elixir and Erlang

* Install Erlang and Elixir:

```shell
# apk add erlang erlang-runtime-tools erlang-xmerl elixir
```

* Install `erlang-eldap` if you want to enable ldap authenticator

```shell
# apk add erlang-eldap
```
### Install PostgreSQL

* Install Postgresql server:

```shell
# apk add postgresql postgresql-contrib
```

* Initialize database:

```shell
FIXME
```

* Enable and start postgresql server:

```shell
# rc-update add postgresql
# service postgresql start
```

### Finalize installation

If you want to open your newly installed instance to the world, you should run nginx or some other webserver/proxy in front of Pleroma and you should consider to create an OpenRC service file for Pleroma.

#### Nginx

* Install nginx, if not already done:

```shell
# apk add nginx
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, first install it:

```shell
# apk add certbot
```

and then set it up:

```shell
# mkdir -p /var/lib/letsencrypt/
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again).

* Copy the example nginx configuration to the nginx folder

```shell
# cp ~pleroma/pleroma/installation/pleroma.nginx /etc/nginx/conf.d/pleroma.conf
```

* Before starting nginx edit the configuration and change it to your needs (e.g. change servername, change cert paths)
* Enable and start nginx:

```shell
# rc-update add nginx
# service nginx start
```

If you need to renew the certificate in the future, uncomment the relevant location block in the nginx config and run:

```shell
# certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

### Install and Configure Pleroma
You can now follow [Generic Pleroma Installation](generic_pleroma_en.html).
