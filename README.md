# Ruby on Railsベースアプリケーション（Space）

運営元とユーザー同士が作成したスペース上で情報共有する（BtoC向け）  
(Ruby 3.4.3, Rails 7.2.2.2)

## 環境構築手順（Dockerの場合） ※構築は早いが、動作は遅い

Ruby/Rails/Gemのバージョンアップや追加に向いている（環境依存が少ない）

### Dockerインストール

#### Docker Desktop

https://docs.docker.com/desktop/

#### OrbStack

https://orbstack.dev/download

### コンテナ作成＆起動

.env.exampleを.envにコピーして、変更（下記はMySQLを使う場合）
```bash
# local
# MYSQL_HOST=127.0.0.1
# POSTGRES_HOST=127.0.0.1

# docker
MYSQL_HOST=mysql
POSTGRES_HOST=pg
```

```bash
# dockerをビルドして起動（Ctrl-Cで強制終了。-dは[make down]で終了）
$ make up（または up-all, up-d, up-all-d）

# データベース・初期データ作成・更新
$ make db
```

- http://localhost:3000
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost:3000/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

### Tips: Railsだけlocalで動かす場合

Railsの設定以外は、下記「環境構築手順（Macの場合）」参照

```bash
# dockerをビルドして起動（Ctrl-Cで強制終了。-dは[make down]で終了）
$ make up-base（または up-base-d）
```

## 環境構築手順（Macの場合） ※構築は手間だが、動作は早い

通常の開発に向いている（開発効率が良い）

### Homebrewインストール

```bash
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
（$ brew update）

# zshの場合(Catalina以降)
% vi ~/.zshrc
# bashの場合
$ vi ~/.bash_profile
```
```bash
### START ###
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
### END ###
```
```bash
# zshの場合(Catalina以降)
% source ~/.zshrc
# bashの場合
$ source ~/.bash_profile

$ brew doctor
Your system is ready to brew.

$ brew -v
Homebrew 5.0.4
# バージョンは異なっても良い
```

### ImageMagickインストール

```bash
$ brew install imagemagick
（$ brew upgrade imagemagick）

$ magick -version
Version: ImageMagick 7.1.2-9 Q16-HDRI aarch64 23451 https://imagemagick.org
# バージョンは異なっても良い
```

### Graphvizインストール

```bash
$ brew install graphviz
（$ brew upgrade graphviz）

$ dot -V
dot - graphviz version 14.0.5 (20251129.0259)
# バージョンは異なっても良い
```

### font-freefontインストール

```bash
$ brew install --cask font-freefont
（$ brew upgrade --cask font-freefont）

$ brew info --cask font-freefont
==> font-freefont: 20120503
# バージョンは異なっても良い
```

### Rubyインストール

```bash
# GPGインストール	# NOTE: Homebrewの最近のバージョンでは、GnuPGはgpgコマンドとしてインストールされる
$ brew install gpg
$ gpg --version
gpg (GnuPG) 2.4.8

# RVMインストール
$ gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
$ 'curl' -sSL https://get.rvm.io | bash -s stable
Donate: https://opencollective.com/rvm/donate
（$ rvm get stable）

$ source ~/.rvm/scripts/rvm
$ rvm -v
rvm 1.29.12 (latest) by Michal Papis, Piotr Kuczynski, Wayne E. Seguin [https://rvm.io]
# バージョンは異なっても良い
```
NOTE: https://github.com/rbenv/homebrew-tap/issues/9#issuecomment-1683015411
```bash
# OpenSSL v3インストール
$ brew install openssl@3
（$ brew upgrade openssl@3）

# zshの場合(Catalina以降)
% source ~/.zshrc
# bashの場合
$ source ~/.bash_profile

$ openssl version
OpenSSL 3.6.0 1 Oct 2025 (Library: OpenSSL 3.6.0 1 Oct 2025)
```
```bash
# Rubyインストール
$ rvm install 3.4.3 --with-openssl-dir=$(brew --prefix openssl@3)
（$ rvm --default use 3.4.3）

$ ruby -v
ruby 3.4.3 (2025-04-14 revision d0b7e5b6a0) +PRISM [arm64-darwin22]

$ rvm list
=* ruby-3.4.3 [ arm64 ]
```

### MariaDB or MySQLインストール

```bash
# MariaDBを使う場合
$ brew install mariadb
（$ brew upgrade mariadb）

$ brew services start mariadb

# MySQLを使う場合
$ brew install mysql
（$ brew upgrade mysql）

$ brew services start mysql
（or $ mysql.server start）
```

※以降の「xyz789」は好きなパスワードに変更してください。
```bash
# MariaDBを使う場合
$ mysql
> SET PASSWORD FOR root@localhost=PASSWORD('xyz789');
> \q

$ mysql_secure_installation
Enter current password for root (enter for none): xyz789
Switch to unix_socket authentication [Y/n] n
Change the root password? [Y/n] n
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y

# MySQLを使う場合
$ mysql_secure_installation
Press y|Y for Yes, any other key for No: n
New password: xyz789
Re-enter new password: xyz789
Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
```

```bash
$ vi ~/.my.cnf
```
```bash
### START ###
[client]
user = root
password = xyz789
### END ###
```
```bash
$ mysql
# MariaDBの場合
Server version: 12.1.2-MariaDB Homebrew
# MySQLの場合
Server version: 9.4.0 Homebrew
# バージョンは異なっても良いが、本番と同じが理想

> \q
```

#### Tips: アンインストール

```bash
# MariaDBの場合
$ brew services stop mariadb
$ brew uninstall mariadb

# MySQLの場合
$ brew services stop mysql
$ brew uninstall mysql

# 両方
$ rm -fr /opt/homebrew/var/mysql
$ rm -fr /opt/homebrew/etc/my.cnf.d
$ rm -f /opt/homebrew/etc/my.cnf*
$ rm -f ~/.my.cnf
```

### PostgreSQLインストール

```bash
$ brew search postgresql
postgresql-hll  postgresql@11   postgresql@12   postgresql@13   postgresql@14   postgresql@15   postgresql@16   postgresql@17   qt-postgresql   postgrest

$ brew install postgresql@17
（$ brew upgrade postgresql@17）

# zshの場合(Catalina以降)
% vi ~/.zshrc
# bashの場合
$ vi ~/.bash_profile
```
```bash
### START ###
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"
### END ###
```
```bash
# zshの場合(Catalina以降)
% source ~/.zshrc
# bashの場合
$ source ~/.bash_profile

$ psql --version
psql (PostgreSQL) 17.6 (Homebrew)
# バージョンは異なっても良いが、本番と同じが理想

$ brew services start postgresql@17
$ createuser -s postgres
```

```bash
$ psql -l
$ psql postgres
psql (17.6 (Homebrew))

# \q
```

#### Tips: アンインストール

```bash
$ brew cleanup --prune-prefix

$ brew services stop postgresql@17
$ brew uninstall postgresql@17
```

### 起動まで

```bash
$ cp -a .env.example .env

# Gemインストール
gem install bundler -v 2.7.2
bundle install -j4 --retry=3
（$ bundle update）

# データベース・初期データ作成・更新
$ make db

# Railsサーバー起動
$ make s

# Job起動
$ make j（または jobs）
```

- http://localhost:3000
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost:3000/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

### Schemaspy

#### Dockerで実行

```bash
# Schemaspy実行
$ make ssd-mysql（または schemaspy-docker-mysql, ssd-mariadb, schemaspy-docker-mariadb, ssd-pg, schemaspy-docker-pg, ssd-sqlite, schemaspy-docker-sqlite）
```

#### localで実行

```bash
# OpenJDKインストール
$ brew install openjdk

# zshの場合(Catalina以降)
% vi ~/.zshrc
# bashの場合
$ vi ~/.bash_profile
```
```bash
### START ###
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
### END ###
```
```bash
# zshの場合(Catalina以降)
% source ~/.zshrc
# bashの場合
$ source ~/.bash_profile

$ java -version
openjdk version "24.0.2" 2025-07-15

# Schemaspy実行
$ make ss-mysql（または schemaspy-mysql, ss-mariadb, schemaspy-mariadb, ss-pg, schemaspy-pg, ss-sqlite, schemaspy-sqlite）
```

## 使い方

### docker

```bash
# dockerコンテナ内に接続
$ make bash
# 新しいdockerコンテナを作成し、コンテナ内に接続
$ make bash-new
```

### 更新

```bash
# データベース・初期データ作成・更新
$ make db

# データベース・初期データリセット
$ make reset

# Gemインストール
$ make install（または bundle）
```

### 起動

```bash
# Railsコンソール起動
$ make c
# Railsコンソール起動（サンドボックスモード）
$ make cs

# Railsサーバー起動
$ make s

# Job起動
$ make j（または jobs）
```

### その他

```bash
# ルーティング確認（パラメータ指定可）
$ make r（または routes）

# RuboCop実行・自動修正
$ make l（または lint, rubocop）

# RSpec実行（パラメータでファイル名指定可）
$ make rspec

# RSpec実行（失敗のみ）
$ make rspec-fail

# Brakeman実行
$ make b（または brakeman）
# Brakeman ignore更新
$ make b-ignore（または brakeman-ignore）

# YARDでドキュメント作成
$ make yard

# ERDでER図作成
$ make erd
```

### Nginxインストール

```bash
$ brew install nginx
（$ brew upgrade nginx）

$ nginx -v
nginx version: nginx/1.29.1
# バージョンは異なっても良い
```
```bash
$ vi /opt/homebrew/etc/nginx/nginx.conf
```
```bash
worker_processes  1;
### START ###
worker_rlimit_nofile 65536;
### END ###

events {
    worker_connections  1024;

http {
### START ###
    server_names_hash_bucket_size 64;
    server_tokens off;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    client_max_body_size 64m;
    gzip on;
    gzip_vary on;
    gzip_proxied no-cache no-store private expired auth;
    gzip_comp_level 5;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss;
### END ###

    #tcp_nopush     on;
### START ###
    tcp_nopush      on;
    tcp_nodelay     on;
### END ###

    #keepalive_timeout  0;
### START ###
#    keepalive_timeout  65;
    keepalive_timeout   120;
    open_file_cache     max=100 inactive=20s;
    types_hash_max_size 2048;
### END ###

    server {
### START ###
#        listen       8080;
        listen       80;
#        server_name  localhost;
        server_name  _;
### END ###
```
```bash
$ vi /opt/homebrew/etc/nginx/servers/localhost.conf
```
```bash
### START ###
server {
    listen       80;
    server_name  localhost;

    location ~ /\.(ht|git|svn|cvs) {
        deny all;
    }

    location / {
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Host    $host;
        proxy_set_header    X-Forwarded-Proto   $scheme;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_redirect      off;
        proxy_pass          http://127.0.0.1:3000;

        proxy_hide_header   X-Runtime;
    }
}
### END ###
```
```bash
# NOTE: ファイルアップロードに失敗する為
$ sudo chmod 770 /opt/homebrew/var/run/nginx

$ nginx -t -c /opt/homebrew/etc/nginx/nginx.conf
nginx: the configuration file /opt/homebrew/etc/nginx/nginx.conf syntax is ok
nginx: configuration file /opt/homebrew/etc/nginx/nginx.conf test is successful

$ brew services start nginx
```
.envを変更
```bash
# BASE_DOMAIN=localhost:3000
# BASE_IMAGE_URL=http://localhost:3000
BASE_DOMAIN=localhost
BASE_IMAGE_URL=http://localhost
```
```bash
# Railsサーバー起動
$ make s

# Job起動
$ make j（または jobs）
```

- http://localhost
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

## デプロイ手順

### Capistrano

```bash
$ cap -T
$ cap production deploy
$ cap production deploy --trace --dry-run
$ cap production unicorn:stop
$ cap production unicorn:start
```

### ECR -> ECS(Fargate)

ALB -> Unicorn(rails-app-origin_app)
ALB -> Nginx(rails-app-origin_web) -> ALB -> Unicorn(rails-app-origin_app)
ALB -> Nginx+Unicorn(rails-app-origin_webapp)

https://ap-northeast-1.console.aws.amazon.com/ecr/public-registry/repositories?region=ap-northeast-1
```bash
docker build --platform=linux/amd64 -f ecs/app/Dockerfile -t rails-app-origin_app .
docker build --platform=linux/amd64 -f ecs/web/Dockerfile -t rails-app-origin_web .
docker build --platform=linux/amd64 -f ecs/webapp/Dockerfile -t rails-app-origin_webapp .

docker tag rails-app-origin_app:latest public.ecr.aws/h7c3l0m6/rails-app-origin_app:latest
docker tag rails-app-origin_web:latest public.ecr.aws/h7c3l0m6/rails-app-origin_web:latest
docker tag rails-app-origin_webapp:latest public.ecr.aws/h7c3l0m6/rails-app-origin_webapp:latest

aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/h7c3l0m6
docker push public.ecr.aws/h7c3l0m6/rails-app-origin_app:latest
docker push public.ecr.aws/h7c3l0m6/rails-app-origin_web:latest
docker push public.ecr.aws/h7c3l0m6/rails-app-origin_webapp:latest
```
