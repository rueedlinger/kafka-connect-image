
# This file contains some of the configurations for the Kafka Connect distributed worker.

{% for key, value in environment('CONNECT_') %}
{{ key | lower | replace("_", ".") }}={{ value -}}
{% endfor %}