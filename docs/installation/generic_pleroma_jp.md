# Pleromaをインストールする (ディストリビューション共通)

## 日本語訳について

この記事は [Generic Pleroma installation](generic_pleroma_en.html) の日本語訳です。何かがおかしいと思ったら、原文を見てください。

## このパートについて

コマンドが `#` で始まるならば、ルートで実行してください。コマンドが `$` で始まるならば、`pleroma` ユーザーで実行してください。コマンドが `%` で始まるならば、特にユーザーの指定はありません。これら以外に特にユーザーの指定が必要なときは `username $` と表記します。

ユーザーを切り替えるときか、exit するよう指示されたときを除いては、セッションを維持してください。

このパートでは以下のことを前提にします。

- Pleromaが依存するすべてのシステムがインストールおよび設定されている。
- `pleroma` ユーザーが存在する。このユーザーはホームディレクトリを持つ。ホームディレクトリは `/opt/pleroma` である。

このパートの終わりには、以下が達成されます。

- Pleromaがインストールされる。Pleromaの設定が `~pleroma/pleroma` に保存される。

## Pleromaのソースコードを取得する

### リリースtarballを使う

(この部分はまだ文書化されていません。)

### Gitを使う
```shell
pleroma $ git clone -b master https://git.pleroma.social/pleroma/pleroma ~pleroma/pleroma
pleroma $ cd ~pleroma/pleroma
```

Note: The `master` branch was selected, you can switch to another one with `git checkout`. However, be aware almost all other branches are based on the `develop` branch (see [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/)), which usually contains database migrations not present in `master`, meaning that if you choose to switch from master you **can't** switch back until the next release.

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
This one is for systems using sytemd, such as: ArchLinux, Debian derivatives, Gentoo with systemd, RedHat-based(ie. CentOS)

* Copy example service file

```shell
# cp ~pleroma/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* Edit the service file and make sure that all paths fit your installation
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
