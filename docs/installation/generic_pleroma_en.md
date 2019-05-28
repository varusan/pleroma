# Generic Pleroma installation

Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

This part assumes:
- You have installed and configured the system dependencies required for pleroma
- You have added a system `pleroma` user with an existent home (it is assumed to be `/var/lib/pleroma`)

And you'll get:
- Pleroma installed and configured in `~pleroma/pleroma`.

## Get pleroma source code
### Using a release tarball

(this needs to be written)

### Using git
```shell
$ cd
$ git clone -b master https://git.pleroma.social/pleroma/pleroma.git ~pleroma/pleroma
$ cd ~pleroma/pleroma
```

Note: The `master` branch was selected, you can switch to another one with `git checkout`. However, be aware almost all other branches are based on the `develop` branch (see [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)), which usually contains database migrations not present in `master`, meaning that if you choose to switch from master you **can't** switch back until the next release.

## Install Elixir dependencies
* Install the dependencies for Pleroma and answer with `Y` if it asks you to install `Hex`:

```shell
$ mix deps.get
```

If you get ``mix: command not found``, a workaround ``$ export PATH=$PATH:/usr/local/bin`` may help you.

## Configuration
* Generate the configuration: ``mix pleroma.instance gen``
  * Answer with `Y` if it asks you to install `rebar3`.
  * This may take some time, because parts of pleroma get compiled first.
  * After that it will ask you a few questions about your instance and generates a configuration file in `config/generated_config.exs`.

* Check the configuration and if all looks right, copy it, so Pleroma will load it (`prod.secret.exs` for production instances, `dev.secret.exs` for development instances):

```shell
$ cp config/generated_config.exs config/prod.secret.exs
```

* If your PostgreSQL's port number is not 5432, add `port` record into `Pleroma.Repo` section in the `prod.secret.exs` and/or `dev.secret.exs`.

* The configuration generator also creates the file `config/setup_db.psql`, with which you can create the database:

```shell
postgres $ psql -U postgres -f config/setup_db.psql
```
Or sometimes following workaround may help you:

```shell
# cat ~pleroma/pleroma/config/setup_db.psql | sudo -Hu postgres psql -U postgres -f -
```

* Change to production mode and make the next `pleroma` sessions default to it:

```shell
$ export MIX_ENV=prod
$ echo MIX_ENV=prod > ~/.profile
```

* Now run the database migration:

```shell
$ mix ecto.migrate
```

* Create the admin account:

```shell
$ mix pleroma.user new <username> <your@emailaddress> --admin
```

* Now you can start Pleroma manually for tests:

```shell
$ mix phx.server
```

## Daemonize
Pick a sub-section depending on your system.

### OpenRC
This one is for systems using OpenRC or compatible, such as: Alpine, Gentoo by default

* Copy example service file

```shell
# cp ~pleroma/pleroma/installation/init.d/pleroma /etc/init.d/
```

* Be sure to take a look at this service file and make sure that all paths fit your installation

* Enable and start `pleroma`:

```shell
# rc-update add pleroma default
# /etc/init.d/pleroma start
```

### Systemd
This one is for systems using sytemd, such as: ArchLinux, Debian derivatives, Gentoo with systemd, RedHat-based (ie. CentOS)

* Copy example service file

```shell
# cp ~pleroma/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* Edit the service file and make sure that all paths fit your installation. Especially `WorkingDirectory=/opt/pleroma` has to be `WorkingDirectory=/var/lib/pleroma/pleroma`.

* Enable and start `pleroma.service`:

```shell
# systemctl enable --now pleroma.service
```

### NetBSD
* Copy the startup script to the correct location and make sure it's executable:

```shell
# cp ~pleroma/pleroma/installation/netbsd/rc.d/pleroma /etc/rc.d/pleroma
# chmod +x /etc/rc.d/pleroma
```

* Add the following to `/etc/rc.conf`:

```
pleroma=YES
pleroma_home="/home/pleroma"
pleroma_user="pleroma"
```

### OpenBSD
* Copy the startup script to the correct location and make sure it's executable:

```shell
# cp ~pleroma/pleroma/installation/openbsd/rc.d/pleromad /etc/rc.d/pleroma
```

* Edit the service file and make sure that all paths fit your installation

* Enable and start `pleroma`:
```shell
# rcctl enable pleroma
# rcctl start pleroma
```

## Support & Questions

For support or questions please ask in the chatroom, available via IRC at `#pleroma` on [Freenode](https://freenode.net/) and via [Matrix on `#freenode_#pleroma:matrix.org`](https://matrix.heldscal.la/#/room/#freenode_#pleroma:matrix.org).
