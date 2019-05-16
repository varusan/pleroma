# Generic Pleroma installation

Commands starting with `#` should be launched as root, with `$` they should be launched as the `pleroma` user, with `%` they can be launched with any user on the machine, in case they need a specific user they’ll be prefixed with `username $`. It is recommended to keep the session until it changes of user or tells you to exit. See [[unix session management]] if you do not know how to do it.

This part assumes:
- You have installed and configured the system dependencies required for pleroma
- You have added a system `pleroma` user with an existent home (it is assumed to be `/opt/pleroma`)

And you'll get:
- Pleroma installed and configured in `~pleroma/pleroma`.

## Get pleroma source code
### Using a release tarball

(this needs to be written)

### Using git
```shell
pleroma $ git clone -b master https://git.pleroma.social/pleroma/pleroma ~pleroma/pleroma
pleroma $ cd ~pleroma/pleroma
```

Note: The `master` branch was selected, you can switch to another one with `git checkout`.

## Install Elixir dependencies
* Install the dependencies for Pleroma and answer with `yes` if it asks you to install `Hex`:

```shell
pleroma $ mix deps.get
```

## Configuration
* Generate the configuration: ``mix pleroma.instance gen``
  * Answer with `yes` if it asks you to install `rebar3`.
  * This may take some time, because parts of pleroma get compiled first.
  * After that it will ask you a few questions about your instance and generates a configuration file in `config/generated_config.exs`.

* Check the configuration and if all looks right, copy it, so Pleroma will load it (`prod.secret.exs` for production instances, `dev.secret.exs` for development instances):

```shell
pleroma $ cp config/generated_config.exs config/prod.secret.exs
```

* The configuration generator also creates the file `config/setup_db.psql`, with which you can create the database:

```shell
% psql -U postgres -f config/setup_db.psql
```

* Change to production mode and make the next `pleroma` sessions default to it:

```shell
pleroma $ export MIX_ENV=prod
pleroma $ echo MIX_ENV=prod > ~/.profile
```

* Now run the database migration:

```shell
pleroma $ mix ecto.migrate
```

* Create the admin account:

```shell
pleroma $ mix pleroma.user new <username> <your@emailaddress> --admin
```

* Now you can start Pleroma manually for tests:

```shell
pleroma $ mix phx.server
```

Pleroma is now installed and configured, you can now start pleroma as a daemon (depends on your system, a de-facto generic way is ``service pleroma start`` as root.

## Support & Questions

For support or questions please ask in the chatroom, available via IRC at `#pleroma` on [Freenode](https://freenode.net/) and via [Matrix on `#freenode_#pleroma:matrix.org`](https://matrix.heldscal.la/#/room/#freenode_#pleroma:matrix.org).
