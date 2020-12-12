log4j.rootLogger={{ CONNECT_LOG4J_ROOT_LOGLEVEL | default('INFO') }}, stdout

# Send the logs to the console.
#
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout

# The `%X{connector.context}` parameter in the layout includes connector-specific and task-specific information
# in the log message, where appropriate. This makes it easier to identify those log messages that apply to a
# specific connector. Simply add this parameter to the log layout configuration below to include the contextual information.
connect.log.pattern={{ CONNECT_LOG4J_APPENDER_STDOUT_LAYOUT_CONVERSIONPATTERN | default('[%d] %p %X{connector.context}%m (%c:%L)%n') }}
#connect.log.pattern=[%d] %p %m (%c:%L)%n

log4j.appender.stdout.layout.ConversionPattern=${connect.log.pattern}

# Default loggers
log4j.logger.org.apache.zookeeper=ERROR
log4j.logger.org.I0Itec.zkclient=ERROR
log4j.logger.org.reflections=ERROR

{% if CONNECT_LOG4J_LOGGERS is defined %}
# Custom loggers
{% set loggers = CONNECT_LOG4J_LOGGERS.split(",") %}
{% for logger in loggers %}
log4j.logger.{{ logger -}}
{% endfor %}
{% endif %}