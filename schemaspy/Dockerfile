# https://hub.docker.com/_/openjdk
FROM openjdk:26-jdk-slim
RUN apt-get update -qq && apt-get install -y tzdata make graphviz

WORKDIR /workdir/schemaspy
ENV TZ='Asia/Tokyo'
