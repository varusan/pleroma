# Pleromaをインストールする (ディストリビューション共通)

## 日本語訳について

この記事は [Generic Pleroma installation](generic_pleroma_en.html) の日本語訳です。何かがおかしいと思ったら、原文を見てください。

## このパートについて

コマンドが `#` で始まるならば、ルートで実行してください。コマンドが `$` で始まるならば、`pleroma` ユーザーで実行してください。コマンドが `%` で始まるならば、特にユーザーの指定はありません。これら以外に特にユーザーの指定が必要なときは `username $` と表記します。

ユーザーを切り替えるときか、exit するよう指示されたときを除いては、セッションを維持してください。

このパートでは以下のことを前提にします。

- Pleromaが依存するすべてのシステムがインストールおよび設定されている。
- `pleroma` ユーザーが存在する。このユーザーはホームディレクトリを持つ。ホームディレクトリは `/var/lib/pleroma` である。

このパートの終わりには、以下が達成されます。

- Pleromaがインストールされる。Pleromaの設定が `~pleroma/pleroma` に保存される。

## Pleromaのソースコードを取得する

### リリースtarballを使う

(この部分はまだ文書化されていません。)

### Gitを使う
```shell
$ git clone -b master https://git.pleroma.social/pleroma/pleroma ~pleroma/pleroma
$ cd ~pleroma/pleroma
```

**注意** いま `master` ブランチが選択されており、`git checkout` で別のブランチに切り替えることができます。しかし、気を付けるべきことがあり、他のほとんどのブランチは `develop` ブランチから派生しています。([GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) を見るとよい。) `develop` とそこから派生したブランチは、データベースのミグレーションを先行して行っており、そのミグレーションは `master` ブランチには反映されていないことがあります。つまり、`master` から別のブランチに切り替えたら、`master` に戻ってくることはおそらく不可能だろうということです。

## Elixirの依存をインストールする
* Pleromaのための依存をインストールします。`Hex` をインストールするか聞かれたら、`Y` と回答してください。

```shell
$ mix deps.get
```

## コンフィギュレーション
* コンフィギュレーションを生成する: ``mix pleroma.instance gen``
  * `rebar3` をインストールするか聞かれたら、`Y` と回答してください。
  * これには時間がかかります。Pleromaをコンパイルするためです。
  * あなたのインスタンスについていくつかの質問があります。コンフィギュレーションファイルが `config/generated_config.exs` に生成されます。

* コンフィギュレーションが正しいかどうか、ファイルの内容を確認してください。もし問題なければ、コピーしてください。Pleromaが読み込むのはコピーのほうです。コピー先のファイル名は、プロダクションインスタンスであれば `prod.secret.exs`、開発インスタンスであれば `dev.secret.exs` です。

```shell
$ cp config/generated_config.exs config/prod.secret.exs
```

* PostgreSQLのポート番号が5432でなければ、コンフィギュレーションファイルの `Pleroma.Repo` セクションに `port` レコードを追加する必要があります。

* 先ほどのコンフィギュレーションジェネレーターは `config/setup_db.psql` というファイルも生成します。これを使ってデータベースを作ります:

```shell
postgres $ psql -U postgres -f config/setup_db.psql
```

* プロダクションモードに変更します。また、`pleroma` ユーザーのセッションが常にプロダクションモードになるようにします。

```shell
$ export MIX_ENV=prod
$ echo MIX_ENV=prod > ~/.profile
```

* ベータベースのミグレーションを実行します。

```shell
$ mix ecto.migrate
```

* 管理者アカウントを作成します。

```shell
$ mix pleroma.user new <username> <your@emailaddress> --admin
```

* ここまで来れば、Pleromaを手動で起動することができます。

```shell
$ mix phx.server
```

## デーモンにする
あなたのシステムによってサブセクションを選んでください。

### OpenRC
この節はOpenRCまたはその互換システムのためのものです。AlpineとGentooではデフォルトです。

* サービスファイルの例をコピーしてください。

```shell
# cp ~pleroma/pleroma/installation/init.d/pleroma /etc/init.d/
```

* このサービスファイルの内容を見て、すべてのパスが正しいことを確認してください。

* `pleroma` サービスをイネーブルおよびスタートします。

```shell
# rc-update add pleroma default
# /etc/init.d/pleroma start
```

### Systemd
この節はsystemdを使うシステムのためのものです。ArchLinux、Debianの子孫たち、Gentoo with systemd、RedHatの子孫たち (CentOSなど) がそうです。

* サービスファイルの例をコピーしてください。

```shell
# cp ~pleroma/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* このサービスファイルの内容を編集して、すべてのパスが正しいことを確認してください。特に `WorkingDirectory=/opt/pleroma` は `WorkingDirectory=/var/lib/pleroma/pleroma` に訂正すべきです。

* `pleroma.service` サービスをイネーブルおよびスタートします。

```shell
# systemctl enable --now pleroma.service
```

### NetBSD
* スタートアップスクリプトを正しい場所にコピーして、実行可能にしてください。

```shell
# cp ~pleroma/pleroma/installation/netbsd/rc.d/pleroma /etc/rc.d/pleroma
# chmod +x /etc/rc.d/pleroma
```

* 以下のコードを `/etc/rc.conf` に追加してください。

```
pleroma=YES
pleroma_home="/home/pleroma"
pleroma_user="pleroma"
```

### OpenBSD
* スタートアップスクリプトを正しい場所にコピーして、実行可能にしてください。

```shell
# cp ~pleroma/pleroma/installation/openbsd/rc.d/pleromad /etc/rc.d/pleroma
```

* サービスファイルの内容を編集して、すべてのパスが正しいことを確認してください。

* `pleroma` サービスをイネーブルおよびスタートします。
```shell
# rcctl enable pleroma
# rcctl start pleroma
```

## 質問ある？

何か質問があれば、以下のチャットルームに来てください。IRCは [Freenode](https://freenode.net/) の `#pleroma` チャンネルです。[Matrix on `#freenode_#pleroma:matrix.org`](https://matrix.heldscal.la/#/room/#freenode_#pleroma:matrix.org) もあります。
