# https://hub.docker.com/_/ruby
FROM ruby:3.2.2-alpine
RUN apk update && apk add --no-cache --update build-base tzdata bash python3 imagemagick graphviz ttf-freefont gcompat
# RUN apk add --no-cache --update sqlite-dev sqlite-libs
RUN apk add --no-cache --update mysql-dev mysql-client
RUN apk add --no-cache --update postgresql-dev postgresql-client
RUN apk add --no-cache --update nginx gettext

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

COPY ecs/web/nginx/nginx.conf.template /etc/nginx/
COPY ecs/web/nginx/conf.d/default.conf.template /etc/nginx/conf.d/
COPY ecs/webapp/nginx/conf.d/unicorn.conf /etc/nginx/conf.d/
COPY public/_check /usr/share/nginx/html/

# Add a script to be executed every time the container starts.
COPY ecs/web/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Configure the main process to run when running the image
# NOTE: assets:precompileは起動時に実施。SECRET_KEY_BASEが必要な為
CMD ["bash", "-c", "nginx && bundle exec rails db:migrate db:seed assets:precompile && bundle exec unicorn -c config/unicorn.rb"]
