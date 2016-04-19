Docker Flink JobManager
============================
Yet another dockerized flink image. It's purpose is to have:
- proper signal handling
- docker friendly logging configurations (rolling file appenders, console)
- a simple runner without using supervisor, zookeeper, docker compose... just calling java directly (while all those things are still possible)
- a convenient way to configure flink through an environment variable (```FLINK_CONF```)

Environment
==============
Several environment variables are supported. The most important are:
- JVM_ARGS: you know, the things like ```-Xmx768m```
- FLINK_ENV_JAVA_OPTS: additional java options for flink, e.g. properties (via -D)
- FLINK_CONF: accepts any YAML string. Can be used to configure (override) everything which resides in flink-conf.yaml. E.g. ```{jobmanager.rpc.port: 6001}```


Examples
============
```run --rm -e "FLINK_CONF={jobmanager.rpc.port: 6001}" lzaugg/flink-jobmanager:1.0.1```