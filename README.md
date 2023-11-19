# Ruby on Railsベースアプリケーション

運営元が情報提供して1つのサービスを作る（BtoC向け）  
(Ruby 3.2.2, Rails 6.1)

## コマンドメモ

| local | Docker |
| - | - |
| | docker compose exec app bash<br>( :/workdir# ) |
| bundle install | docker compose run app bundle install |
| yarn install | docker compose run app yarn install |
| rails db:migrate | docker compose run app rails db:migrate |
| rails db:seed | docker compose run app rails db:seed |
| rails s | 不要 |
| bin/webpack-dev-server | 不要 |
| rails jobs:work<br>または bin/delayed_job start| 不要 |
| rails c | docker compose run app rails c |
| rails db | docker compose run app rails db |
| rspec<br>open coverage/index.html | docker compose run app rspec<br>open coverage/index.html |
| rubocop | docker compose run app rubocop |
| brakeman | docker compose run app brakeman |
| yard<br>open doc/index.html | docker compose run app yard<br>open doc/index.html |
| erd<br>open db/erd.pdf | docker compose run app erd<br>open db/erd.pdf |
| cd schemaspy<br>make schemaspy<br>( open analysis/index.html ) | cd schemaspy<br>make docker-schemaspy<br>( open analysis/index.html ) |

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

$ docker compose run app rails db:create
$ docker compose run app rails db:migrate
$ docker compose run app rails db:seed
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
Homebrew 4.1.20
※バージョンは異なっても良い
```

### ImageMagickインストール

```
$ brew install imagemagick
（$ brew upgrade imagemagick）

$ magick -version
Version: ImageMagick 7.1.1-21 Q16-HDRI aarch64 21667 https://imagemagick.org
※バージョンは異なっても良い
```

### Graphvizインストール

```
$ brew install graphviz
（$ brew upgrade graphviz）

$ dot -V
dot - graphviz version 9.0.0 (20230911.1827)
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

※ターミナルを開き直して、
$ openssl version
OpenSSL 3.1.4 24 Oct 2023 (Library: OpenSSL 3.1.4 24 Oct 2023)

$ rvm install 3.2.2 --with-openssl-dir=$(brew --prefix openssl@3)
（$ rvm --default use 3.2.2）

$ ruby -v
ruby 3.2.2 (2023-03-30 revision e51014f9c0) [arm64-darwin22]

$ rvm list
   ruby-3.1.4 [ arm64 ]
=* ruby-3.2.2 [ arm64 ]
```

### Node.jsインストール

```
$ brew install nvm
（$ brew upgrade nvm）
$ mkdir ~/.nvm

※zshの場合(Catalina以降)
% vi ~/.zshrc
※bashの場合
$ vi ~/.bash_profile
---- ここから ----
### START ###
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
### END ###
---- ここまで ----

※zshの場合(Catalina以降)
% source ~/.zshrc
※bashの場合
$ source ~/.bash_profile

$ nvm --version
0.39.5
※バージョンは異なっても良い
```
```
$ nvm ls-remote | grep 'Latest LTS'
       v16.20.2   (Latest LTS: Gallium)
       v18.18.2   (Latest LTS: Hydrogen)
        v20.9.0   (Latest LTS: Iron)

$ nvm install v16.20.2
（$ nvm use v16.20.2）
（$ nvm alias default v16.20.2）
※バージョンは異なっても良いが、本番の環境に合わせるのがベスト

※bin/webpack-dev-serverでエラーになる
v18.18.2 -> Error: error:0308010C:digital envelope routines::unsupported
v20.9.0 -> Error: spawn node-gyp ENOENT

$ node -v
v16.20.2

$ nvm ls
->     v16.20.2
         system
default -> v16.20.2
```

### yarnインストール

```
$ brew install yarn
（$ brew upgrade yarn）

※zshの場合(Catalina以降)
% vi ~/.zshrc
※bashの場合
$ vi ~/.bash_profile
---- ここから ----
export PATH="/opt/homebrew/opt/icu4c/bin:/opt/homebrew/opt/icu4c/sbin:$PATH"
---- ここまで ----

※zshの場合(Catalina以降)
% source ~/.zshrc
※bashの場合
$ source ~/.bash_profile

$ yarn -v
1.22.21
※バージョンは異なっても良い
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

### 起動まで

```
$ cd rails-app-origin
$ cp -a config/settings/development.yml,local config/settings/development.yml

$ bundle install
（$ bundle update）
Bundle complete!

$ yarn install
（$ yarn upgrade）
Done

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
