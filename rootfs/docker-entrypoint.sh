#!/usr/bin/env bash
set -e

if [ -z "$CONNECT_BOOTSTRAP_SERVERS" ]; then
    echo "Missing configuration CONNECT_BOOTSTRAP_SERVERS"
    exit 1
fi

if [ -z "$CONNECT_GROUP_ID" ]; then
    echo "Missing configuration CONNECT_GROUP_ID"
    exit 1
fi

if [ -z "$CONNECT_CONFIG_STORAGE_TOPIC" ]; then
    echo "Missing configuration CONNECT_CONFIG_STORAGE_TOPIC"
    exit 1
fi

if [ -z "$CONNECT_OFFSET_STORAGE_TOPIC" ]; then
    echo "Missing configuration CONNECT_OFFSET_STORAGE_TOPIC"
    exit 1
fi

if [ -z "$CONNECT_STATUS_STORAGE_TOPIC" ]; then
    echo "Missing configuration CONNECT_STATUS_STORAGE_TOPIC"
    exit 1
fi

if [ -z "$CONNECT_KEY_CONVERTER" ]; then
    echo "Missing configuration CONNECT_KEY_CONVERTER"
    exit 1
fi

if [ -z "$CONNECT_VALUE_CONVERTER" ]; then
    echo "Missing configuration CONNECT_VALUE_CONVERTER"
    exit 1
fi

if [ -z "$CONNECT_REST_ADVERTISED_HOST_NAME" ]; then
    echo "Missing configuration CONNECT_REST_ADVERTISED_HOST_NAME"
    exit 1
fi

# set defaults

if [ -z "$CLASSPATH" ]; then
    export CLASSPATH="/connect/jars/*"
fi

if [ -z "$CONNECT_PLUGIN_PATH" ]; then
    export CONNECT_PLUGIN_PATH="$CONNECT_HOME/plugins,/usr/local/share/java"
fi


if [ -z "$CONNECT_INTERNAL_KEY_CONVERTER" ]; then
    export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
    export CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE="false"
fi

if [ -z "$CONNECT_INTERNAL_VALUE_CONVERTER" ]; then
    export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
    export CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE="false"
fi

if [ -z "$CONNECT_REST_PORT" ]; then
    export CONNECT_REST_PORT="8083"
fi

if [ -z "$TZ" ]; then
    export TZ="UTC"
fi

echo "Creating configuration..."
# set timeone
cp /usr/share/zoneinfo/$TZ $CONNECT_HOME/etc/localtime 
echo $TZ > $CONNECT_HOME/etc/timezone

# create connect configuration
envtpl -o $CONNECT_LOG_CONFIG $CONNECT_HOME/templates/connect-log4j.properties.tpl
envtpl -o $CONNECT_WORKER_CONFIG $CONNECT_HOME/templates/connect-distributed.properties.tpl

echo "Starting Apache Kafka Connect..."
connect-distributed.sh $CONNECT_HOME/etc/connect-distributed.properties
