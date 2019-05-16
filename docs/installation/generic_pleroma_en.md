# Generic Pleroma installation

This part assumes:
- You have installed and configured the system dependencies required for pleroma
- You have added a system `pleroma` user with an existent home (it is assumed to be `/opt/pleroma`)
- You are logged into the `pleroma` user and are in it’s home (run `cd` without arguments to be sure)

And you'll get:
- Pleroma installed and configured in `~pleroma/pleroma`.

## Get pleroma source code
### Using a release tarball

(this needs to be written)

### Using git
```shell
git clone -b master https://git.pleroma.social/pleroma/pleroma
cd pleroma
```

Note: The `master` branch was selected, you can switch to another one with `git checkout`.

## Install Elixir dependencies
* Install the dependencies for Pleroma and answer with `yes` if it asks you to install `Hex`:

```shell
mix deps.get
```

## Configuration
* Generate the configuration: `sudo -Hu pleroma mix pleroma.instance gen`
  * Answer with `yes` if it asks you to install `rebar3`.
  * This may take some time, because parts of pleroma get compiled first.
  * After that it will ask you a few questions about your instance and generates a configuration file in `config/generated_config.exs`.

* Check the configuration and if all looks right, rename it, so Pleroma will load it (`prod.secret.exs` for productive instance, `dev.secret.exs` for development instances):

```shell
mv config/{generated_config.exs,prod.secret.exs}
```

* The configuratio generation also creates the file `config/setup_db.psql`, with which you can create the database:

```shell
psql -U postgres -f config/setup_db.psql
```

* Change to production mode and make the next `pleroma` sessions default to it:

```shell
export MIX_ENV=prod
echo MIX_ENV=prod > ~/.profile
```

* Now run the database migration:

```shell
mix ecto.migrate
```

* Create the admin account:

```shell
mix pleroma.user new <username> <your@emailaddress> --admin
```

* Now you can start Pleroma manually for tests:

```shell
mix phx.server
```

Pleroma is now installed and configured, you can now start pleroma as a daemon (depends on your system, a de-facto generic way is ``service pleroma start`` as root.

## Support & Questions

For support or questions please ask in the chatroom, available via IRC at `#pleroma` on [Freenode](https://freenode.net/) and via [Matrix on `#freenode_#pleroma:matrix.org`](https://matrix.heldscal.la/#/room/#freenode_#pleroma:matrix.org).
