# https://hub.docker.com/_/ruby
FROM ruby:3.4.3-alpine
RUN apk add --no-cache \
    tzdata \
    build-base \
    yaml-dev \
    linux-headers \
    # SQLite
    sqlite-dev \
    sqlite-libs \
    # MySQL
    mysql-dev \
    mysql-client \
    # PostgreSQL
    postgresql-dev \
    postgresql-client \
    # 実行時に必要
    bash \
    shared-mime-info \
    imagemagick \
    imagemagick-dev \
    graphviz \
    ttf-freefont \
    # 以降はdevelopmentのみ
    yarn \
    musl-locales \
    musl-locales-lang \
    coreutils \
    busybox-extras \
    git \
    curl \
    vim

WORKDIR /workdir
ENV TZ='Asia/Tokyo'

# developmentのみ
ENV LANG='ja_JP.UTF-8'
ENV LC_ALL='ja_JP.UTF-8'

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.7.2 && \
    bundle install -j4 --retry=3

# developmentのみ
COPY package.json yarn.lock ./
RUN yarn install

# developmentは不要
# COPY . .

# developmentのみ
RUN echo -e "\
export LS_OPTIONS='--color=auto'\n\
eval \"\$(dircolors -b)\"\n\
alias ls='ls \$LS_OPTIONS'\n\
alias ll='ls -lF'\n\
alias l='ls -lAF'\n\
alias rm='rm -i'\n\
alias cp='cp -i'\n\
alias mv='mv -i'\
" >> ~/.bashrc
