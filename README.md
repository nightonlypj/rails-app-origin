# Ruby on Railsベースアプリケーション

運営元が情報提供して1つのサービスを作る（BtoC向け）  
(Ruby 3.3.4, Rails 7.1.3.4)

## コマンドメモ

| local | Docker |
| - | - |
| | docker compose exec app bash<br>( :/workdir# ) |
| bundle install | docker compose run app bundle install |
| rails db:migrate | docker compose run app rails db:migrate |
| rails db:seed | docker compose run app rails db:seed |
| rails s | 不要 |
| rails jobs:work<br>または bin/delayed_job start| 不要 |
| rails c | docker compose run app rails c |
| rails db | docker compose run app rails db |
| rspec<br>open coverage/index.html | docker compose run app rspec<br>open coverage/index.html |
| rubocop | docker compose run app rubocop |
| brakeman | docker compose run app brakeman |
| yard<br>open doc/index.html | docker compose run app yard<br>open doc/index.html |
| erd<br>open db/erd.pdf | docker compose run app erd<br>open db/erd.pdf |
| cd schemaspy<br>make schemaspy<br>( open analysis/index.html ) | cd schemaspy<br>make docker-schemaspy<br>( open analysis/index.html ) |

### Capistrano

```
cap -T
cap production deploy
cap production deploy --trace --dry-run
cap production unicorn:stop
cap production unicorn:start
```

### ECR -> ECS(Fargate)

ALB -> Unicorn(rails-app-origin_app)
ALB -> Nginx(rails-app-origin_web) -> ALB -> Unicorn(rails-app-origin_app)
ALB -> Nginx+Unicorn(rails-app-origin_webapp)

https://ap-northeast-1.console.aws.amazon.com/ecr/public-registry/repositories?region=ap-northeast-1
```
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

## 環境構築手順（Dockerの場合）

### Dockerインストール

Docker Desktop for Macをダウンロードして、普通にインストール  
https://hub.docker.com/editions/community/docker-ce-desktop-mac/

### コンテナ作成＆起動

config/database.yml
```
  host: 127.0.0.1
↓
  host: db
```

```
$ cd rails-app-origin

$ docker compose build
$ docker compose up
または $ docker compose up --build
```
※終了は、Ctrl+C

```
$ cp -a config/settings/development.yml,local config/settings/development.yml

※初回のみ /config/credentials.yml.encとmaster.keyが作成される。環境により変えた方が良い。
$ rails credentials:edit

$ docker compose run app rails db:create
$ docker compose run app rails db:migrate
$ docker compose run app rails db:seed
または $ docker compose run app rails db:create db:migrate db:seed
```

- http://localhost:3000
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost:3000/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

### Tips: DBだけ使う

DBの設定以外は、下記「環境構築手順（Macの場合）」参照

```
$ docker compose up db
```

## 環境構築手順（Macの場合）

### Homebrewインストール

```
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
Warning: /opt/homebrew/bin is not in your PATH.
（$ brew update）

※zshの場合(Catalina以降)
% vi ~/.zshrc
※bashの場合
$ vi ~/.bash_profile
---- ここから ----
### START ###
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
### END ###
---- ここまで ----

※zshの場合(Catalina以降)
% source ~/.zshrc
※bashの場合
$ source ~/.bash_profile

$ brew doctor
Your system is ready to brew.

$ brew -v
Homebrew 4.3.21
※バージョンは異なっても良い
```

### ImageMagickインストール

```
$ brew install imagemagick
（$ brew upgrade imagemagick）

$ magick -version
Version: ImageMagick 7.1.1-38 Q16-HDRI aarch64 22398 https://imagemagick.org
※バージョンは異なっても良い
```

### Graphvizインストール

```
$ brew install graphviz
（$ brew upgrade graphviz）

$ dot -V
dot - graphviz version 12.1.1 (20240910.0053)
※バージョンは異なっても良い
```

### Rubyインストール

```
$ brew install gpg2
$ gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
gpg:           インポート: 2  (RSA: 2)

$ 'curl' -sSL https://get.rvm.io | bash -s stable
Donate: https://opencollective.com/rvm/donate
（$ rvm get stable）

$ source ~/.rvm/scripts/rvm
$ rvm -v
rvm 1.29.12 (latest) by Michal Papis, Piotr Kuczynski, Wayne E. Seguin [https://rvm.io]
※バージョンは異なっても良い
```

https://github.com/rbenv/homebrew-tap/issues/9#issuecomment-1683015411
```
$ brew install openssl@3
（$ brew upgrade openssl@3）

※ターミナルを開き直して、
$ openssl version
OpenSSL 3.3.2 3 Sep 2024 (Library: OpenSSL 3.3.2 3 Sep 2024)

$ rvm install 3.3.4 --with-openssl-dir=$(brew --prefix openssl@3)
（$ rvm --default use 3.3.4）

$ ruby -v
ruby 3.3.4 (2024-07-09 revision be1089c8ec) [arm64-darwin22]

$ rvm list
=* ruby-3.3.4 [ arm64 ]
```

### MariaDB or MySQLインストール

```
※MariaDBを使う場合
$ brew install mariadb
（$ brew upgrade mariadb）
※MySQLを使う場合
$ brew install mysql
（$ brew upgrade mysql）

※MariaDBを使う場合
$ brew services start mariadb
※MySQLを使う場合
$ brew services start mysql
（or $ mysql.server start）
```

※以降の「xyz789」は好きなパスワードに変更してください。
```
※MariaDBを使う場合
$ mysql
> SET PASSWORD FOR root@localhost=PASSWORD('xyz789');
> \q

$ mysql_secure_installation
※MariaDBを使う場合
Enter current password for root (enter for none): xyz789
Switch to unix_socket authentication [Y/n] n
Change the root password? [Y/n] n
※MySQLを使う場合
Press y|Y for Yes, any other key for No: n
New password: xyz789
Re-enter new password: xyz789

Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
```

```
$ vi ~/.my.cnf
---- ここから ----
### START ###
[client]
user = root
password = xyz789
### END ###
---- ここまで ----

$ mysql
※MariaDBの場合
Server version: 11.1.3-MariaDB Homebrew
※MySQLの場合
Server version: 8.0.23 Homebrew
※バージョンは異なっても良いが、本番と同じが理想

> \q
```

#### Tips: アンインストール

```
※MariaDBの場合
$ brew services stop mariadb
$ brew uninstall mariadb
※MySQLの場合
$ brew services stop mysql
$ brew uninstall mysql

$ rm -fr /opt/homebrew/var/mysql
$ rm -fr /opt/homebrew/etc/my.cnf.d
$ rm -f /opt/homebrew/etc/my.cnf*
$ rm -f ~/.my.cnf
```

### PostgreSQLインストール

```
$ brew search postgresql
postgresql@10     postgresql@11     postgresql@12     postgresql@13     postgresql@14     postgresql@15     postgresql@16     qt-postgresql     postgrest

$ brew install postgresql@16
（$ brew upgrade postgresql@16）

※zshの場合(Catalina以降)
% vi ~/.zshrc
※bashの場合
$ vi ~/.bash_profile
---- ここから ----
### START ###
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/postgresql@16/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@16/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/postgresql@16/lib/pkgconfig"
### END ###
---- ここまで ----

※zshの場合(Catalina以降)
% source ~/.zshrc
※bashの場合
$ source ~/.bash_profile

$ psql --version
psql (PostgreSQL) 16.1 (Homebrew)
※バージョンは異なっても良いが、本番と同じが理想

$ brew services start postgresql@16
```

```
% psql -l
% psql postgres
psql (16.1 (Homebrew))

# \q
```

#### Tips: アンインストール

```
$ brew services stop postgresql@14
$ brew uninstall postgresql@14
```

### 起動まで

```
$ cd rails-app-origin
$ cp -a config/settings/development.yml,local config/settings/development.yml

$ bundle install
（$ bundle update）
Bundle complete!

※初回のみ /config/credentials.yml.encとmaster.keyが作成される。環境により変えた方が良い。
$ rails credentials:edit

$ rails db:create
$ rails db:migrate
※「Mysql2::Error: Specified key was too long; max key length is 767 bytes」の場合は「rails db:migrate:reset」で回避

$ rails db:seed
$ rails s
（$ bin/webpack-dev-server）
（$ rails jobs:work または bin/delayed_job start）
```

- http://localhost:3000
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost:3000/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

### Nginxインストール

```
$ brew install nginx
（$ brew upgrade nginx）

$ nginx -v
nginx version: nginx/1.25.1
※バージョンは異なっても良い
```
```
$ vi /opt/homebrew/etc/nginx/nginx.conf
---- ここから ----
worker_processes  1;
### START ###
worker_rlimit_nofile 65536;
### END ###
---- ここまで ----
---- ここから ----
events {
    worker_connections  1024;
### START ###
    accept_mutex_delay 100ms;
    multi_accept on;
### END ###
---- ここまで ----
---- ここから ----
http {
### START ###
    server_names_hash_bucket_size 64;
    server_tokens off;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;
    client_max_body_size 64m;
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript application/x-javascript application/json text/xml application/xml application/xml+rss;
### END ###
---- ここまで ----
---- ここから ----
    #tcp_nopush     on;
### START ###
    tcp_nopush      on;
    tcp_nodelay     on;
### END ###
---- ここまで ----
---- ここから ----
    #keepalive_timeout  0;
### START ###
#    keepalive_timeout  65;
    keepalive_timeout   120;
    open_file_cache     max=100 inactive=20s;
    types_hash_max_size 2048;
### END ###
---- ここまで ----
---- ここから ----
    server {
### START ###
#        listen       8080;
        listen       80;
#        server_name  localhost;
        server_name  _;
### END ###
---- ここまで ----
```
```
$ vi /opt/homebrew/etc/nginx/servers/localhost.conf
---- ここから ----
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
    }
}
### END ###
---- ここまで ----

※Tips: ファイルアップロードに失敗する為
$ sudo chmod 770 /opt/homebrew/var/run/nginx/*

$ nginx -t -c /opt/homebrew/etc/nginx/nginx.conf
nginx: the configuration file /opt/homebrew/etc/nginx/nginx.conf syntax is ok
nginx: configuration file /opt/homebrew/etc/nginx/nginx.conf test is successful

$ brew services start nginx
```
```
$ cp -a config/settings/development.yml,dev config/settings/development.yml
overwrite config/settings/development.yml? (y/n [n]) y

$ rails s
（$ bin/webpack-dev-server）
（$ rails jobs:work または bin/delayed_job start）
```

- http://localhost
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照
