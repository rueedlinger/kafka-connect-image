FROM alpine:3.9 

USER root
WORKDIR /tmp

ENV LANG="C.UTF-8"
ENV PATH="/usr/local/kafka/bin:$PATH"

ENV KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:/connect/etc/connect-log4j.properties"
ENV LOG_DIR="/var/log/kafka"

RUN addgroup -g 1000 kafka-connect-group && \
    adduser -u 1000 -G kafka-connect-group -D kafka-connect


RUN wget https://cdn.azul.com/public_keys/alpine-signing@azul.com-5d5dc44c.rsa.pub && \
    mv alpine-signing@azul.com-5d5dc44c.rsa.pub /etc/apk/keys/ && \
    echo "https://repos.azul.com/zulu/alpine" >> /etc/apk/repositories  && \
    apk update && \
    apk upgrade && \
    apk add bash python3 zulu11-jdk-headless jq tzdata

RUN ln -sf python3 /usr/bin/python && \
    ln -sf pip3 /usr/bin/pip && \
    python -m ensurepip && \
    pip install --no-cache --upgrade pip setuptools envtpl

RUN wget https://downloads.apache.org/kafka/2.6.0/kafka_2.13-2.6.0.tgz && \
    tar -xvzf kafka_2.13-2.6.0.tgz -C /usr/local && \
    rm kafka_2.13-2.6.0.tgz && \
    ln -s /usr/local/kafka_2.13-2.6.0 /usr/local/kafka    


RUN mkdir -p /connect/etc && \
    mkdir -p /connect/jars && \
    mkdir -p /connect/plugins && \
    mkdir -p /var/log/kafka && \
    mkdir -p /usr/local/share/java

RUN cp /usr/share/zoneinfo/UTC /connect/etc/localtime && \
    echo UTC > /connect/etc/timezone  && \
    ln -s /connect/etc/timezone /etc/timezone && \
    ln -s /connect/etc/localtime /etc/localtime

# Install Apache Kafka Connect plugins
RUN wget https://github.com/farmdawgnation/registryless-avro-converter/releases/download/1.10.0/registryless-avro-converter-1.10.0.jar && \
    mkdir /connect/plugins/registryless-avro-converter && \
    mv registryless-avro-converter-1.10.0.jar /connect/plugins/registryless-avro-converter && \
    wget http://packages.confluent.io/archive/6.0/confluent-community-6.0.1.zip && \
    unzip confluent-community-6.0.1.zip && \
    mv confluent-6.0.1/share/java/kafka-serde-tools /connect/plugins/confluent-kafka-serde-tools && \
    rm -rf confluent-*


ADD rootfs /

RUN chown -R kafka-connect:kafka-connect-group /connect  && \
    chown -R kafka-connect:kafka-connect-group /var/log/kafka

USER kafka-connect

ENTRYPOINT ["/docker-entrypoint.sh"]
