# Debianベースのディストリビューションにインストールする
## 日本語訳について

この記事は [Installing on Debian based distributions](https://docs-develop.pleroma.social/debian_based_en.html) の日本語訳です。何かがおかしいと思ったら、原文を見てください。

## インストール

このガイドはステップ・バイ・ステップのインストールガイドです。Debianベースのディストリビューション、特にDebian Stretchを仮定しています。

コマンドが `#` で始まるならば、ルートで実行してください。コマンドが `$` で始まるならば、`pleroma` ユーザーで実行してください。コマンドが `%` で始まるならば、特にユーザーの指定はありません。これら以外に特にユーザーの指定が必要なときは `username $` と表記します。

ユーザーを切り替えるときか、exit するよう指示されたときを除いては、セッションを維持してください。

### 必要なパッケージ

* `postgresql` (9.6以上。Ubuntu 16.04のPostgreSQLは9.5なので、[新しいバージョンを取得する](https://www.postgresql.org/download/linux/ubuntu/)必要がある。)
* `postgresql-contrib` (9.6以上。同上。)
* `elixir` (1.7以上。[DebianとUbuntuのパッケージは古いので、ここからインストールすること](https://elixir-lang.org/install.html#unix-and-unix-like)。または、[asdf](https://github.com/asdf-vm/asdf)をpleromaユーザーで使うこと。)
* `erlang-dev`
* `erlang-tools`
* `erlang-parsetools`
* `erlang-eldap`
* `erlang-xmerl`
* `erlang-ssh`
* `git`
* `build-essential`

#### オプションのパッケージ

* `nginx` (推奨。他のリバースプロクシの設定の雛形も用意されている。)
* `certbot` (または他のACMEクライアント。)

### システムを準備する

* まずシステムをアップデートしてください。

```shell
# apt update
# apt full-upgrade
```

* 必要なソフトウェアの一部をインストールします。

```shell
# apt install git build-essential postgresql postgresql-contrib
```

* 新しいユーザーを作成します。

```shell
# useradd -r -s /bin/false -m -d /var/lib/pleroma -U pleroma
```

### ElixirとErlangをインストールします

* Erlangのリポジトリをダウンロードおよび追加します。

```shell
% wget -P /tmp/ https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
# dpkg -i /tmp/erlang-solutions_1.0_all.deb
```

* ElixirとErlangをインストールします

```shell
# apt update
# apt install elixir erlang-dev erlang-parsetools erlang-xmerl erlang-ssh erlang-tools
```

### Nginxをインストールします

* Nginxをインストールします。

```shell
# apt install nginx
```

* SSLをセットアップします。certbotでよければ、まずそれをインストールします。

```shell
# apt install certbot
```

certbotをセットアップします。

```shell
# mkdir -p /var/lib/letsencrypt/
# certbot certonly --email <your@emailaddress> -d <yourdomain> --standalone
```

もしうまくいかないならば、nginxが動作していないことを確認してください。それでもうまくいかないならば、先にnginxを設定 (ssl "on" を "off" に変える) してから再試行してください。

---

* nginxコンフィギュレーションの例をコピーおよびアクティベートします。

```shell
# cp /opt/pleroma/installation/pleroma.nginx /etc/nginx/sites-available/pleroma.nginx
# ln -s /etc/nginx/sites-available/pleroma.nginx /etc/nginx/sites-enabled/pleroma.nginx
```
* nginxを起動する前に、コンフィギュレーションを編集してください。例えば、サーバー名、証明書のパスなどを変更する必要があります。

* nginxをイネーブルおよび起動します。

```shell
# systemctl enable --now nginx.service
```
もし未来に証明書を延長する必要があるならば、nginxのコンフィグのリリバント・ロケーション・ブロックをアンコメントして、以下を実行してください。

```shell
# certbot certonly --email <your@emailaddress> -d <yourdomain> --webroot -w /var/lib/letsencrypt/
```

#### 他のウェブサーバーとプロクシ

他のコンフィグレーションの例は `/opt/pleroma/installation/` にあります。

### Systemd サービス

* サービスファイルの例をコピーします。

```shell
sudo cp /opt/pleroma/installation/pleroma.service /etc/systemd/system/pleroma.service
```

* サービスファイルを変更します。すべてのパスが正しいことを確認してください。
* `pleroma.service` をイネーブルおよび起動します。

```shell
sudo systemctl enable --now pleroma.service
```

### Pleromaのインストールとコンフィギュレーション

[installation/generic_pleroma_en.md](Generic Pleroma Installation) に進んでください。