FROM ruby:3.4.3-alpine AS builder
RUN apk add --no-cache \
    build-base \
    yaml-dev \
    linux-headers \
    # MySQL
    mysql-dev \
    # PostgreSQL
    postgresql-dev

WORKDIR /workdir

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.7.2 && \
    bundle config set --local without 'test development' && \
    bundle install -j4 --retry=3

COPY . .

FROM ruby:3.4.3-alpine
RUN apk add --no-cache \
    tzdata \
    bash \
    shared-mime-info \
    imagemagick \
    imagemagick-dev \
    graphviz \
    ttf-freefont \
    # MySQL
    mysql-client \
    # PostgreSQL
    postgresql-client \
    # Nginx
    nginx \
    gettext

WORKDIR /workdir
ENV TZ='Asia/Tokyo'

ENV RAILS_ENV="production"
ENV RAILS_LOG_TO_STDOUT=1

COPY --from=builder /workdir ./
COPY --from=builder /usr/local/bundle /usr/local/bundle
RUN mkdir -p tmp/pids tmp/sockets

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
