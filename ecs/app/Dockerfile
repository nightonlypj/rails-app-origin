# https://hub.docker.com/_/ruby
FROM ruby:3.2.2-alpine
RUN apk update && apk add --no-cache --update build-base tzdata bash python3 imagemagick graphviz ttf-freefont gcompat
# RUN apk add --no-cache --update sqlite-dev sqlite-libs
RUN apk add --no-cache --update mysql-dev mysql-client
RUN apk add --no-cache --update postgresql-dev postgresql-client

WORKDIR /workdir
ENV LANG="ja_JP.UTF-8"

ENV RAILS_ENV="production"
ENV RAILS_LOG_TO_STDOUT=1

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'test development'
RUN bundle install --no-cache

COPY . ./
RUN mkdir -p tmp/pids
RUN mkdir -p tmp/sockets

# NOTE: 存在チェック
COPY public/robots.txt ./public/

# Configure the main process to run when running the image
# NOTE: assets:precompileは起動時に実施。SECRET_KEY_BASEが必要な為
CMD ["bash", "-c", "bundle exec rails db:migrate db:seed assets:precompile && bundle exec unicorn -c config/unicorn.rb"]
