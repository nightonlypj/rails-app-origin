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
    postgresql-client

WORKDIR /workdir
ENV TZ='Asia/Tokyo'

ENV RAILS_ENV="production"
ENV RAILS_LOG_TO_STDOUT=1

COPY --from=builder /workdir ./
COPY --from=builder /usr/local/bundle /usr/local/bundle
RUN mkdir -p tmp/pids tmp/sockets

# NOTE: 存在チェック
COPY public/robots.txt ./public/

# Configure the main process to run when running the image
# NOTE: assets:precompileは起動時に実施。SECRET_KEY_BASEが必要な為
CMD ["bash", "-c", "bundle exec rails db:migrate db:seed assets:precompile && bundle exec unicorn -c config/unicorn.rb"]
