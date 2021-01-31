# Ruby on Railsベースアプリケーション

運営元が情報提供して1つのサービスを作る（BtoC向け）
(Ruby 3.0.0, Rails 6.0.3.4)

## 環境構築手順（Macの場合）

### Homebrewインストール

$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
> Warning: /opt/homebrew/bin is not in your PATH.

※zshの場合(Catalina以降)  
% vi ~/.zshrc  
※bashの場合  
$ vi ~/.bash_profile
```
### START ###
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
### END ###
```

※zshの場合(Catalina以降)  
% source ~/.zshrc  
※bashの場合  
$ source ~/.bash_profile

$ brew doctor
> Your system is ready to brew.

$ brew -v
> Homebrew 2.7.5

### ImageMagickインストール

$ brew install imagemagick

$ magick -version
> Version: ImageMagick 7.0.10-58 Q16 arm 2021-01-16 https://imagemagick.org

### node.jsインストール

$ brew install nvm  
$ mkdir ~/.nvm

※zshの場合(Catalina以降)  
% vi ~/.zshrc  
※bashの場合  
$ vi ~/.bash_profile
```
### START ###
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
### END ###
```

※zshの場合(Catalina以降)  
% source ~/.zshrc  
※bashの場合  
$ source ~/.bash_profile

$ nvm --version
> 0.37.2

$ nvm ls-remote | grep 'Latest LTS'
>        v14.15.4   (Latest LTS: Fermium)

$ nvm install 14.15.4

$ node -v
> v14.15.4

### yarnインストール

$ brew install yarn

※zshの場合(Catalina以降)  
% vi ~/.zshrc  
※bashの場合  
$ vi ~/.bash_profile  
```
export PATH="/opt/homebrew/opt/icu4c/bin:/opt/homebrew/opt/icu4c/sbin:$PATH"
```

※zshの場合(Catalina以降)  
% source ~/.zshrc  
※bashの場合  
$ source ~/.bash_profile

$ yarn -v
> 1.22.10

### MySQLインストール

$ brew install mysql@5.7

※zshの場合(Catalina以降)  
% vi ~/.zshrc  
※bashの場合  
$ vi ~/.bash_profile
```
export PATH="/opt/homebrew/opt/mysql@5.7/bin:$PATH"
```

※zshの場合(Catalina以降)  
% source ~/.zshrc  
※bashの場合  
$ source ~/.bash_profile

$ mysql.server start

$ mysql_secure_installation
```
Press y|Y for Yes, any other key for No: n
New password: xyz789
Re-enter new password: xyz789
Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
```

$ vi ~/.my.cnf
```
### START ###
[client]
user = root
password = xyz789
### END ###
```

$ mysql
> Server version: 5.7.32 Homebrew

mysql> \q

### Rubyインストール

$ brew install gpg2  
$ gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB  
$ 'curl' -sSL https://get.rvm.io | bash -s stable  
$ source ~/.rvm/scripts/rvm

$ rvm -v
> rvm 1.29.12 (latest) by Michal Papis, Piotr Kuczynski, Wayne E. Seguin [https://rvm.io]

$ rvm list known
> [ruby-]3[.0.0]

$ rvm install 3.0

$ ruby -v
> ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [arm64-darwin20]

### データベースとユーザー作成

$ mysql
```
CREATE DATABASE rails_app_development;
CREATE USER 'rails_app'@'%' IDENTIFIED BY 'abc123';
GRANT ALL PRIVILEGES ON rails_app_development.* TO 'rails_app'@'%';
CREATE DATABASE rails_app_test;
CREATE USER 'rails_app_test'@'%' IDENTIFIED BY 'abc123'; 
GRANT ALL PRIVILEGES ON rails_app_test.* TO 'rails_app_test'@'%';
\q
```

### Gemインストールから起動まで

$ cd rails-app-origin  
$ cp -a config/settings/development.yml,local config/settings/development.yml

$ bundle install

$ rails webpacker:install
```
Overwrite config/webpacker.yml? (enter "h" for help) [Ynaqdhm] n
```

$ rails db:migrate  
$ rails db:seed  
$ rails s

- http://localhost:3000
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost:3000/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照

### Nginxインストール

$ brew install nginx

$ nginx -v
> nginx version: nginx/1.19.6

$ vi /opt/homebrew/etc/nginx/nginx.conf
```
worker_processes  1;
### START ###
worker_rlimit_nofile 65536;
### END ###
```
```
events {
    worker_connections  1024;
### START ###
    accept_mutex_delay 100ms;
    multi_accept on;
### END ###
```
```
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
```
```
    #tcp_nopush     on;
### START ###
    tcp_nopush      on;
    tcp_nodelay     on;
### END ###
```
```
    #keepalive_timeout  0;
### START ###
#    keepalive_timeout  65;
    keepalive_timeout   120;
    open_file_cache     max=100 inactive=20s;
    types_hash_max_size 2048;
### END ###
```
```
    server {
### START ###
#        listen       8080;
        listen       80;
#        server_name  localhost;
        server_name  _;
### END ###
```

$ vi /opt/homebrew/etc/nginx/servers/localhost.local.conf
```
### START ###
server {
    listen       80;
    server_name  localhost.local;

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
```

※Tips: ファイルアップロードに失敗する為  
$ sudo chmod 770 /opt/homebrew/var/run/nginx/*

$ nginx -t -c /opt/homebrew/etc/nginx/nginx.conf
> nginx: the configuration file /opt/homebrew/etc/nginx/nginx.conf syntax is ok  
> nginx: configuration file /opt/homebrew/etc/nginx/nginx.conf test is successful

$ brew services start nginx

PCのhostsに下記を追加
```
$ sudo vi /etc/hosts
127.0.0.1       localhost.local
```

$ cp -a config/settings/development.yml,dev config/settings/development.yml  
overwrite config/settings/development.yml? (y/n [n]) y

$ rails s

- http://localhost.local
  - メールアドレスとパスワードは、`db/seed/development/users.yml`参照
- http://localhost.local/admin
  - メールアドレスとパスワードは、`db/seed/admin_users.yml`参照
