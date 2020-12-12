FROM alpine:3.9 

USER root
WORKDIR /tmp

EXPOSE 8083

ENV LANG="C.UTF-8"

ENV CONNECT_HOME="/usr/local/connect"
ENV KAFKA_HOME="/usr/local/kafka"
ENV CONFLUENT_HUB_HOME="/usr/local/confluent-hub"

ENV CONNECT_WORKER_CONFIG="$CONNECT_HOME/etc/connect-distributed.properties"
ENV CONNECT_LOG_CONFIG="$CONNECT_HOME/etc/connect-log4j.properties"

ENV PATH="$KAFKA_HOME/bin:$CONFLUENT_HUB_HOME/bin:$PATH"
ENV LOG_DIR="/var/log"

# Default Kafka logging settings
ENV KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$CONNECT_LOG_CONFIG"

# user and group for running Apache Kafka Connect
RUN addgroup -g 1000 kafka-connect-group && \
    adduser -u 1000 -G kafka-connect-group -D kafka-connect

# Install Alpine Linux packages
RUN wget https://cdn.azul.com/public_keys/alpine-signing@azul.com-5d5dc44c.rsa.pub && \
    mv alpine-signing@azul.com-5d5dc44c.rsa.pub /etc/apk/keys/ && \
    echo "https://repos.azul.com/zulu/alpine" >> /etc/apk/repositories  && \
    apk update && \
    apk upgrade && \
    apk add bash python3 zulu11-jdk-headless jq tzdata curl

# Install python and python modules
RUN ln -sf python3 /usr/bin/python && \
    ln -sf pip3 /usr/bin/pip && \
    python -m ensurepip && \
    pip install --no-cache --upgrade pip setuptools envtpl

# Install Apache Kafka binaries
RUN wget https://downloads.apache.org/kafka/2.6.0/kafka_2.13-2.6.0.tgz && \
    tar -xvzf kafka_2.13-2.6.0.tgz -C /usr/local && \
    rm kafka_*.tgz && \
    ln -s /usr/local/kafka_2.13-2.6.0 $KAFKA_HOME    

# Install confluent-hub-client binary
RUN wget http://client.hub.confluent.io/confluent-hub-client-6.0.0-package.tar.gz && \
    mkdir -p $CONFLUENT_HUB_HOME  && \
    tar -xvzf confluent-hub-client-6.0.0-package.tar.gz -C $CONFLUENT_HUB_HOME && \
    rm confluent-hub-client-*.tar.gz
   
# Create Kafka Connect directories
RUN mkdir -p $CONNECT_HOME/etc && \
    mkdir -p $CONNECT_HOME/templates && \
    mkdir -p $CONNECT_HOME/jars && \
    mkdir -p $CONNECT_HOME/plugins && \
    mkdir -p /usr/local/share/java && \
    mkdir -p $LOG_DIR

# Install timezone and localtime configuration
RUN cp /usr/share/zoneinfo/UTC $CONNECT_HOME/etc/localtime && \
    echo UTC > $CONNECT_HOME/etc/timezone  && \
    ln -s $CONNECT_HOME/etc/timezone /etc/timezone && \
    ln -s $CONNECT_HOME/etc/localtime /etc/localtime

# Install Apache Kafka Connect plugins
RUN wget https://github.com/farmdawgnation/registryless-avro-converter/releases/download/1.10.0/registryless-avro-converter-1.10.0.jar && \
    mkdir $CONNECT_HOME/plugins/registryless-avro-converter && \
    mv registryless-avro-converter-1.10.0.jar $CONNECT_HOME/plugins/registryless-avro-converter && \
    wget http://packages.confluent.io/archive/6.0/confluent-community-6.0.1.zip && \
    unzip confluent-community-6.0.1.zip && \
    mv confluent-6.0.1/share/java/kafka-serde-tools $CONNECT_HOME/plugins/confluent-kafka-serde-tools && \
    rm -rf confluent-*

# Copy the root filesystem and templates
ADD rootfs /
ADD templates $CONNECT_HOME/templates

# create dummy config so that downstream images do not break when 
# they want to use the confluent hub cli to install connectors
RUN envtpl -o $CONNECT_WORKER_CONFIG $CONNECT_HOME/templates/connect-distributed.properties.tpl

# Set file permission for Apache Kafka Connect
RUN chown -R kafka-connect:kafka-connect-group $CONNECT_HOME && \
    chown -R kafka-connect:kafka-connect-group /usr/local/share/java && \
    chown -R kafka-connect:kafka-connect-group $LOG_DIR

USER kafka-connect

ENTRYPOINT ["/docker-entrypoint.sh"]
