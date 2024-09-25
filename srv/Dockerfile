FROM ubuntu:21.04

RUN apt-get update && apt-get -y install sudo curl nano openjdk-8-jdk mc && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64

WORKDIR /app

COPY . .

RUN sudo dpkg -i *.deb && rm -rf *.deb

COPY ring /opt/1C/1CE/x86_64/ring/

RUN chmod 777 *.sh && ./init.sh
