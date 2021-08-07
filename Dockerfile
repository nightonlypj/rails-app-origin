# https://hub.docker.com/_/ruby
FROM ruby:3.0.0-alpine
RUN apk update && apk add --no-cache --update build-base tzdata bash yarn python2 imagemagick graphviz ttf-freefont
RUN apk add --no-cache --update sqlite-dev
RUN apk add --no-cache --update mysql-dev mysql-client
RUN apk add --no-cache --update postgresql-dev postgresql-client

WORKDIR /workdir
ENV LANG="ja_JP.UTF-8"

COPY Gemfile Gemfile.lock ./
RUN bundle install --no-cache

COPY package.json yarn.lock ./
RUN yarn install && yarn cache clean

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]