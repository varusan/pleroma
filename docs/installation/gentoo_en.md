# Installing on Gentoo Linux
## Installation

This guide is a step-by-step installation guide for Gentoo Linux.
Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

### USE flags

The only specific USE flag you should need is the `uuid` flag for `dev-db/postgresql`. Add the following line to any new file in `/etc/portage/package.use`. If you would like a suggested name for the file, either `postgresql` or `pleroma` would do fine, depending on how you like to arrange your package.use flags.

```text
dev-db/postgresql uuid
```

You could opt to add `USE="uuid"` to `/etc/portage/make.conf` if you'd rather set this as a global USE flags, but this flags does unrelated things in other packages, so keep that in mind if you elect to do so.

Double check your compiler flags in `/etc/portage/make.conf`. If you require any special compilation flags or would like to set up remote builds, now is the time to do so. Be sure that your CFLAGS and MAKEOPTS make sense for the platform you are using. It is not recommended to use above `-O2` or risky optimization flags for a production server.

### Installing a cron daemon

Gentoo quite pointedly does not come with a cron daemon installed, and as such it is recommended you install one to automate certbot renewals and to allow other system administration tasks to be run automatically. Gentoo has [a whole wide world of cron options](https://wiki.gentoo.org/wiki/Cron) but if you just want A Cron That Works, `emerge --ask virtual/cron` will install the default cron implementation (probably cronie) which will work just fine. For the purpouses of this guide, we will be doing just that.

### Required ebuilds

* `dev-db/postgresql`
* `dev-lang/elixir`
* `dev-vcs/git`

#### Optional ebuilds used in this guide

* `www-servers/nginx` (preferred, example configs for other reverse proxies can be found in the repo)
* `app-crypt/certbot` (or any other ACME client for Let’s Encrypt certificates)
* `app-crypt/certbot-nginx` (nginx certbot plugin that allows use of the all-powerful `--nginx` flag on certbot)

### Prepare the system

* First ensure that you have the latest copy of the portage ebuilds if you have not synced them yet:

```shell
# emaint sync -a
```

* Emerge all required the required and suggested software in one go:

```shell
# emerge --ask dev-db/postgresql dev-lang/elixir dev-vcs/git www-servers/nginx app-crypt/certbot app-crypt/certbot-nginx
```

* Add a new system user for the Pleroma service and set up default directories:

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

If you would not like to install the optional packages, remove them from this line. 

If you're running this from a low-powered virtual machine, it should work though it will take some time. There were no issues on a VPS with a single core and 1GB of RAM; if you are using an even more limited device and run into issues, you can try creating a swapfile or use a more powerful machine running Gentoo to [cross build](https://wiki.gentoo.org/wiki/Cross_build_environment). If you have a wait ahead of you, now would be a good time to take a break, strech a bit, refresh your beverage of choice and/or get a snack, and reply to Arch users' posts with "I use Gentoo btw" as we do.

### Install PostgreSQL

[Gentoo  Wiki article](https://wiki.gentoo.org/wiki/PostgreSQL) as well as [PostgreSQL QuickStart](https://wiki.gentoo.org/wiki/PostgreSQL/QuickStart) might be worth a quick glance, as the way Gentoo handles postgres is slightly unusual, with built in capability to have two different databases running for testing and live or whatever other purpouse. While it is still straightforward to install, it does mean that the version numbers used in this guide might change for future updates, so keep an eye out for the output you get from `emerge` to ensure you are using the correct ones.

Important Note: This guide will assume that `dev-db/postgresql:11` is the latest stable slot on your architecture, feel free to change it to something else, just note that pleroma require PostgreSQL 9.6+.

* Make sure you have installed PostgreSQL:

```shell
# emerge --ask --noreplace dev-db/postgresql:11
```

Ensure that `/etc/conf.d/postgresql-11` has the encoding you want (it defaults to UTF8 which is probably what you want) and make any adjustments to the data directory if you find it necessary. Be sure to adjust the number at the end depending on what version of postgres you actually installed.

* Initialize the database cluster:

The output from emerging postgresql should give you a command for initializing the postgres database. The default slot should be indicated in this command, ensure that it matches the command below.

```shell
# emerge --config dev-db/postgresql:11
```

* Start postgres and enable the system service
 
```shell
# /etc/init.d/postgresql-11 start
# rc-update add postgresql-11 default
 ```
 
#### Nginx

* Make sure you have installed nginx:

```shell
# emerge --ask --noreplace www-servers/nginx
```

* Create directories for available and enabled sites:

```shell
# mkdir -p /etc/nginx/sites-{available,enabled}
```

* Append the following line at the end of the `http` block in `/etc/nginx/nginx.conf`:

```Nginx
include sites-enabled/*;
```

* Setup your SSL cert, using your method of choice or certbot. If using certbot, install it if you haven't already:

```shell
# emerge --ask app-crypt/certbot app-crypt/certbot-nginx
```

and then set it up:

```shell
# mkdir -p /var/lib/letsencrypt/
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

If that doesn't work the first time, add `--dry-run` to further attempts to avoid being ratelimited as you identify the issue, and do not remove it until the dry run succeeds. If that doesn’t work, make sure, that nginx is not already running. If it still doesn’t work, try setting up nginx first (change ssl “on” to “off” and try again). Often the answer to issues with certbot is to use the `--nginx` flag once you have nginx up and running.

If you are using any additional subdomains, such as for a media proxy, you can re-run the same command with the subdomain in question. When it comes time to renew later, you will not need to run multiple times for each domain, one renew will handle it.

---

* Copy the example nginx configuration and activate it:

```shell
# cp /home/pleroma/pleroma/installation/pleroma.nginx /etc/nginx/sites-available/
# ln -s /etc/nginx/sites-available/pleroma.nginx /etc/nginx/sites-enabled/pleroma.nginx
```

* Take some time to ensure that your nginx config is correct

Replace all instances of `example.tld` with your instance's public URL. If for whatever reason you made changes to the port that your pleroma app runs on, be sure that is reflected in your configuration.

Pay special attention to the line that begins with `ssl_ecdh_curve`. It is stongly advised to comment that line out so that OpenSSL will use its full capabilities, and it is also possible you are running OpenSSL 1.0.2 necessitating that you do this.

* Enable and start nginx:

if you use OpenRC (default on gentoo):
```shell
# rc-update add nginx default
# /etc/init.d/nginx start
```

if you use SystemD:
```shell
# systemctl enable --now nginx.service
```

If you are using certbot, it is HIGHLY recommend you set up a cron job that renews your certificate, and that you install the suggested `certbot-nginx` plugin. If you don't do these things, you only have yourself to blame when your instance breaks suddenly because you forgot about it.

First, ensure that the command you will be installing into your crontab works.

```shell
 # /usr/bin/certbot renew --nginx
```

Assuming not much time has passed since you got certbot working a few steps ago, you should get a message for all domains you installed certificates for saying `Cert not yet due for renewal`. 

Now, run crontab as a superuser with `crontab -e` or `sudo crontab -e` as appropriate, and add the following line to your cron:

```cron
0 0 1 * * /usr/bin/certbot renew --nginx
```

This will run certbot on the first of the month at midnight. If you'd rather run more frequently, it's not a bad idea, feel free to go for it.

#### Other webserver/proxies

If you would like to use other webservers or proxies, there are example configurations for some popular alternatives in `/home/pleroma/pleroma/installation/`. You can, of course, check out [the Gentoo wiki](https://wiki.gentoo.org) for more information on installing and configuring said alternatives.

#### register as a service
##### OpenRC (default)

* Copy example service file

```shell
 # cp /home/pleroma/pleroma/installation/init.d/pleroma /etc/init.d/
```

* Be sure to take a look at this service file and make sure that all paths fit your installation

* Enable and start `pleroma`:

```shell
 # rc-update add pleroma default
 # /etc/init.d/pleroma start
```

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

#### Privilege cleanup

If you opted to allow sudo for the `pleroma` user but would like to remove the ability for greater security, now might be a good time to edit `/etc/sudoers` and/or change the groups the `pleroma` user belongs to. Be sure to restart the pleroma service afterwards to ensure it picks up on the changes.

### Install and Configure Pleroma
You can now follow [installation/generic_pleroma_en.md](Generic Pleroma Installation).
