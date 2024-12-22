# https://hub.docker.com/_/openjdk
FROM openjdk:25-jdk-slim
RUN apt-get update -qq && apt-get install -y graphviz make

WORKDIR /workdir/schemaspy
ENV LANG="ja_JP.UTF-8"
