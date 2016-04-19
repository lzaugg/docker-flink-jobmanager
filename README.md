flink JobManager for Docker
============================

- proper signal handling
- docker friendly logging configuration (rolling file appenders, console)
- simple runner without using supervisor, zookeeper, docker compose... just calling java directly

Environment
==============
- JVM_ARGS
- FLINK_ENV_JAVA_OPTS
- FLINK_CONF: accepts any YAML string. Can be used to configure (override) everything which resides in flink-conf.yaml