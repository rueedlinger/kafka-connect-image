# Apache Kafka Connect Image
Docker image for deploying and running Apache Kafka Connect. The Docker image is based on Alpine Linux and contains:
- Apache Kafka 2.6
- Java 11 (zulu11-jdk-headless)
- Confluent Hub Client

The following Apache Kafka Connect plugins are already installed:
- The [Registryless Avro Converter](https://github.com/farmdawgnation/registryless-avro-converter) which uses Avro without a schema registry.
- The confluent *kafka-serde-tools* from the [Confluent Schema Registry](https://github.com/confluentinc/schema-registry) which contains the Avro, Protobuf and JSON schema convertors). 

## CI Build
- ![CI Build](https://github.com/rueedlinger/kafka-connect-image/workflows/CI%20Build/badge.svg)

## Build and Run (docker-compose)

To build an run the Apache Kafka Connect image just run the following command.

```bash
docker-compose up --build
```

This will start the following Docker containers:
- `zookeeper` => Apache Zookeeper (`confluentinc/cp-zookeeper`)
- `broker` => Apache Kafka (`confluentinc/cp-kafka`)
- `schema-registry`=> Schema Registry (`confluentinc/cp-schema-registry`)
- `connect`=> The plain Apache Kafka Connect Docker image [Dockerfile](Dockerfile)
- `kafdrop`=> Kafdrop – Kafka Web UI  (`obsidiandynamics/kafdrop`)
- `connect-ui` => Kafka Connect UI from Lenses.io (`landoop/kafka-connect-ui`)

When all containers are started you can access different services like 
- **Kafka Connect Rest API** => http://localhost:8083/
- **Kafdrop** => http://localhost:8082/
- **Schema Registry** => http://localhost:8081/
- **kafka-connect-ui** from Lenses.io  => http://localhost:8000/


## Docker Image

The Docker image is also published in Docker Hub.
- see https://hub.docker.com/r/rueedlinger/kafka-connect

```bash
docker pull rueedlinger/kafka-connect:v1.0.0
```
## Releases
There are the following releases:

| Release  | Description  |
|---|---|
| `main` | This is the current release of the main branch. |
| `<major>.<minor>.<path>` | The release `<major>.<minor>.<path>`. For example `1.0.1` and tag `v1.0.1` |

| Release  | Kafka Version  | Java Version
|---|---|---|
|1.0.x| 2.6.x| 11 |

## How to Install Other Plugins

If you want to install other Kafka Connect plugins (Connectors, SMT, etc.) you have two options:

1. Create a *Dockerfile* and install the plugin with the confluent-hub CLI.
```
FROM rueedlinger/kafka-connect:1.0.0

# Install connectors from Confluent Hub with convenience script.
# This will install the plugin in $CONNECT_HOME/plugins
RUN confluent-hub-install confluentinc/kafka-connect-jdbc:10.0.1

# Or directly with confluent-hub CLI
# confluent-hub install confluentinc/kafka-connect-jdbc:10.0.1 \
#   --component-dir $CONNECT_HOME/plugins \
#   --worker-configs $CONNECT_WORKER_CONFIG \
#   --no-prompt
```

2. Create a *Dockerfile* and place the connector in one of the Kafka Connect plugin directories.
```
FROM rueedlinger/kafka-connect:1.0.0

# Add the connector plugin to /usr/local/share/java 
ADD connector.jar /usr/local/share/java

# Or add the connector $CONNECT_HOME/plugins
# ADD connector.jar $CONNECT_HOME/plugins
```

**Note**: If you want to install Kafka Consumer or Producer interceptors, you should place them in  $CONNECT_HOME/jars. Because `$CONNECT_HOME/jars` is added to `CLASSPATH` when starting Apache Kafka Connect.

## Configuration
All environment variables with the prefix `CONNECT_`are used to configure Apache Kafka Connect. 
For example `CONNECT_BOOTSTRAP_SERVERS=foo` is mapped to Connect configuration `bootstrap.servers=foo`.

> **Note:** The setup and configuration is inspired by the Confluent Apache Kafka Connect Docker image.

### Environment Variables
The following environment variables  are set.

| Environment Variable | Description | Default |
|---|---|---|
| CONNECT_HOME | The path to Apache Kafka Connect configuration files, plugin directory and classpath directory. | `/usr/local/connect` |
| KAFKA_HOME | The location of the Kafka binaries. | `/usr/local/kafka` |
| CONFLUENT_HUB_HOME | The location of the Confluent Hub cli | `/usr/local/confluent-hub` |
| CONNECT_WORKER_CONFIG | The path to Apache Kafka Connect worker configuration file.   | `$CONNECT_HOME/etc/connect-distributed.properties` |
| CONNECT_LOG_CONFIG | The path to Apache Kafka Connect logging configuration file. | `$CONNECT_HOME/etc/connect-log4j.properties` |
|  KAFKA_LOG4J_OPTS | Kafka logging configuration | `-Dlog4j.configuration=file:$CONNECT_LOG_CONFIG` |
| PATH | The default PATH variable | `$KAFKA_HOME/bin:$CONFLUENT_HUB_HOME/bin:$PATH` |
| LOG_DIR |LOG_DIR parameter (defines the path name of the directory to which system execution logs are to be output) |`/var/log`|


### Required Configuration

The following configuration settings are required.

| Configuration | Description |
|-------------|-------------|
| CONNECT_BOOTSTRAP_SERVERS | A host:port pair for establishing the initial connection to the Kafka cluster. Multiple bootstrap servers can be used in the form `host1:port1,host2:port2,host3:port3....`|
| CONNECT_GROUP_ID | A unique string that identifies the Connect cluster group this worker belongs to.|
| CONNECT_CONFIG_STORAGE_TOPIC | The name of the topic in which to store connector and task configuration data. This must be the same for all workers with the same `group.id` |
| CONNECT_OFFSET_STORAGE_TOPIC | The name of the topic in which to store offset data for connectors. This must be the same for all workers with the same `group.id` |
| CONNECT_STATUS_STORAGE_TOPIC | The name of the topic in which to store state for connectors. This must be the same for all workers with the same `group.id` |
| CONNECT_KEY_CONVERTER | Converter class for keys. This controls the format of the data that will be written to Kafka for source connectors or read from Kafka for sink connectors. |
| CONNECT_VALUE_CONVERTER | Converter class for values. This controls the format of the data that will be written to Kafka for source connectors or read from Kafka for sink connectors. |
| CONNECT_REST_ADVERTISED_HOST_NAME | The hostname that will be given out to other workers to connect to. In a Docker environment, your clients must be able to connect to the Connect and other services. Advertised hostname is how Connect gives out a hostname that can be reached by the client. |


### Optional Configuration
When nothing else is set the following defaults are used.

| Configuration | Description | Default |
|---|---|---|
| TZ | The TZ environment variable is used to establish the local time zone. Valid values are `Europe/Zurich`, `America/New_York`, `Europe/Dublin`, ... | `UTC` |
| LANG | The LANG environment variable controls the locale of the host. | `C.UTF-8` |
| CLASSPATH | The Classpath which is set for Apache Kafka Connect. | `$CONNECT_HOME/jars/*` |
| CONNECT_PLUGIN_PATH | The plugin.path value that indicates the location from which to load Connect plugins in classloading isolation. | `$CONNECT_HOME/plugins,/usr/local/share/java` |
| CONNECT_INTERNAL_KEY_CONVERTER | Converter class for internal keys that implements the `Converter` interface. | `org.apache.kafka.connect.json.JsonConverter` with `value.converter.schemas.enable=true` |
| CONNECT_INTERNAL_VALUE_CONVERTER | Converter class for internal values that implements the `Converter` interface. | `org.apache.kafka.connect.json.JsonConverter` with `key.converter.schemas.enable=true`|
| CONNECT_REST_PORT | Port for the REST API to listen on. | `8083` |
| CONNECT_LOG4J_ROOT_LOGLEVEL | The root log level. | `INFO` |
| CONNECT_LOG4J_LOGGERS | There is also an option to override other log4j properties. Valid options are `org.apache.zookeeper=ERROR,org.I0Itec.zkclient=ERROR,org.reflections=ERROR` | - |
| CONNECT_LOG4J_APPENDER_STDOUT_LAYOUT_CONVERSIONPATTERN | The logging format which is used. | `'[%d] %p %X{connector.context}%m (%c:%L)%n'`|



### Confluent Hub Client
Confluent Hub Client is installed in the Docker image and can be used to install connectors from [Confluent Hub](https://www.confluent.io/hub/).

Just run 
```bash
confluent-hub install <connector> \
   --component-dir $CONNECT_HOME/plugins \
   --worker-configs $CONNECT_WORKER_CONFIG \
   --no-prompt
```

or use the convenience script `confluent-hub-install` which has all the required properties already set.
```bash
confluent-hub-install <connector> 
```