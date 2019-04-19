# Installing on NetBSD

This guide is a step-by-step installation guide for NetBSD.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

## Required software 

pkgin should have been installed by the NetBSD installer if you selected
the right options. If it isn't installed, install it using pkg_add.

Note that `postgresql11-contrib` is needed for the Postgres extensions
Pleroma uses.

The `mksh` shell is needed to run the Elixir `mix` script.

`# pkgin install acmesh elixir git-base git-docs mksh nginx postgresql11-server postgresql11-client postgresql11-contrib sudo`

You can also build these packages using pkgsrc:
```
databases/postgresql11-contrib
databases/postgresql11-client
databases/postgresql11-server
devel/git-base
devel/git-docs
lang/elixir
security/acmesh
security/sudo
shells/mksh
www/nginx
```

Copy the rc.d scripts to the right directory:

```
# cp /usr/pkg/share/examples/rc.d/nginx /usr/pkg/share/examples/rc.d/pgsql /etc/rc.d
```

Add nginx and Postgres to `/etc/rc.conf`:

```
nginx=YES
pgsql=YES
```

## Configuring the system

Create a user for Pleroma:

```
# groupadd pleroma
# useradd -d /home/pleroma -m -g pleroma -s /usr/pkg/bin/mksh pleroma
# echo 'export LC_ALL="en_GB.UTF-8"' >> /home/pleroma/.profile
```

Also make sure your time is in sync, or other instances will receive your posts with
incorrect timestamps. You should have ntpd running.

## Configuring postgres

First, run `# /etc/rc.d/pgsql start`. Then, `$ sudo -Hu pgsql -g pgsql createdb`.

Postgres allows connections from all users without a password by default. To
fix this, edit `/usr/pkg/pgsql/data/pg_hba.conf`. Change every `trust` to
`password`.

Once this is done, restart Postgres with `# /etc/rc.d/pgsql restart`.

## Configuring nginx

Install the example configuration file
`/home/pleroma/pleroma/installation/pleroma.nginx` to
`/usr/pkg/etc/nginx.conf`.

Note that it will need to be wrapped in a `http {}` block. You should add
settings for the nginx daemon outside of the http block, for example:

```
user                    nginx  nginx;
error_log               /var/log/nginx/error.log;
worker_processes        4;

events {
}
```

Edit the defaults:

* Change `ssl_certificate` and `ssl_trusted_certificate` to
`/etc/nginx/tls/fullchain`.
* Change `ssl_certificate_key` to `/etc/nginx/tls/key`.
* Change `example.tld` to your instance's domain name.

## Configuring acme.sh

We'll be using acme.sh in Stateless Mode for TLS certificate renewal.

First, get your account fingerprint:

```
$ sudo -Hu nginx -g nginx acme.sh --register-account
```

You need to add the following to your nginx configuration for the server
running on port 80:

```
  location ~ ^/\.well-known/acme-challenge/([-_a-zA-Z0-9]+)$ {
    default_type text/plain;
    return 200 "$1.6fXAG9VyG0IahirPEU2ZerUtItW2DHzDzD9wZaEKpqd";
  }
```

Replace the string after after `$1.` with your fingerprint.

Start nginx:

```
# /etc/rc.d/nginx start
```

It should now be possible to issue a cert (replace `example.com`
with your domain name):

```
$ sudo -Hu nginx -g nginx acme.sh --issue -d example.com --stateless
```

Let's add auto-renewal to `/etc/daily.local`
(replace `example.com` with your domain):

```
/usr/pkg/bin/sudo -Hu nginx -g nginx \
    /usr/pkg/sbin/acme.sh -r \
    -d example.com \
    --cert-file /etc/nginx/tls/cert \
    --key-file /etc/nginx/tls/key \
    --ca-file /etc/nginx/tls/ca \
    --fullchain-file /etc/nginx/tls/fullchain \
    --stateless
```

## Creating a startup script for Pleroma

Copy the startup script to the correct location and make sure it's executable:

```
# cp /home/pleroma/pleroma/installation/netbsd/rc.d/pleroma /etc/rc.d/pleroma
# chmod +x /etc/rc.d/pleroma
```

Add the following to `/etc/rc.conf`:

```
pleroma=YES
pleroma_home="/home/pleroma"
pleroma_user="pleroma"
```

## Conclusion

Restart nginx with `# /etc/rc.d/nginx restart` and you should be up and running.

If you need further help, contact niaa on freenode.

## Instances running NetBSD

* <https://catgirl.science>
