Docker Flink JobManager
============================
This repository holds yet another flink build definition for docker to run Flink in containers. There exists a build definition for the Flink jobmanager and one for the Flink taskmanager. The motivation to create this build definition was to get Flink running in Docker with multiple docker containers distributed on different machines (e.g. AWS ElasticBeanstalk, AWS ECS, ..).

The built docker image has (more or less):
- proper signal handling
- docker friendly logging configurations (rolling file appenders, console)
- a minimal footprint (thanks to alpine linux)
- a simple runner without using supervisor, zookeeper, docker compose... just calling java directly (while all those other things are still possible)
- a convenient way to configure flink through environment variables (`FLINK_CONF`,..)
- patched version of Flink 1.0.1 with akka 2.4.4 to support NATed netty with bind hostname and exposed hostname (check tag of docker image!)

Warning / Flink Patching
-------------
This docker image is provided "AS IS", without warranty of any kind. To be able to use Flink with a more docker friendly setup in a NATed environment (e.g. AWS ECS), the following was necessary :
- expose additional akka configuration properties through the Flink configuration mechanism
- update akka version from 2.3.x to 2.4.4 (and therefore only Scala 2.11 is supported)

See https://github.com/lzaugg/flink.git#1.0.1_akka-2.4.4 for changes.

The same idea is already documented in https://issues.apache.org/jira/browse/FLINK-2821 (from another person), but I needed it now and for the stable 1.0.1 release of Flink. The configuration options of akka are described in http://doc.akka.io/docs/akka/snapshot/additional/faq.html.


Quick Start
-------------
```
$ # start jobmanager
$ docker run -e FLINK_ADVERTISED_HOST_NAME=192.168.99.100 -p 6123:6123 -p 6124:6124 -p 8081:8081 lzaugg/flink-jobmanager:1.0.1_akka-2.4.4
$ 
$ # start taskmanager
$ docker run -e FLINK_JOBMANAGER_HOST_NAME=192.168.99.100 lzaugg/flink-taskmanager:1.0.1_akka-2.4.4
```

### Volumes
The container exposes 3 volumes:

- `/flink/logs`: logging
- `/flink/tmp`: tmp directory for taskmanager
- `/flink/blob`: blob directory for taskmanager

### Ports and Linking
- `6123`: JobManager RPC port
- `6124`: JobManager "BlobManager" port
- `8081`: JobManager Web Frontend port

Environment
-------------
Several environment variables are supported. The most important are:

- `JVM_ARGS`

  You know, the things like `-Xmx768m`

- `FLINK_ENV_JAVA_OPTS`

  Additional java options for flink, e.g. properties (via -D).

- `FLINK_CONF`

  Accepts any YAML string to configure Flink. Can be used to override flink-conf.yaml parameters. E.g. `{jobmanager.rpc.port: 6120}`. See Configuration section.

- `FLINK_ADVERTISED_HOST_NAME`

  Hostname to be used to connect to this jobmanager from external (e.g. taskmanagers). It's just an easier way than setting `FLINK_CONF` to `akka.remote.netty.tcp.hostname: <external-ip>`. SHOULD BE SET.

- FLINK_ADVERTISED_PORT

  Port to be used to connect to this jobmanager from external. Default 6123.

Configuration
--------------
Just the most important configuration properties and their defaults. For a full list see https://ci.apache.org/projects/flink/flink-docs-master/setup/config.html:

- `jobmanager.rpc.port: 6123`

  jobmanager rpc server port. Exposed.

- `jobmanager.rpc.address: 0.0.0.0`

  Binds the jobmanager rpc server to any available network interface

- `jobmanager.web.port: 8081`

  jobmanager server web port. Exposed.

- `env.log.dir: /flink/log`

  logging directory. Available as volume.

- `blob.server.port: 6124`

  blob server port. Exposed.

- `blob.storage.directory: /flink/blob`

  blob storage directory: Available as volume.

- `akka.remote.netty.tcp.hostname: FLINK_ADVERTISED_HOST_NAME-not-configured`

  External hostname. SHOULD be overridden either through `FLINK_ADVERTISED_HOST_NAME` or `FLINK_CONF`. ATTENTION: should be an ip address when setting this property directly (through FLINK_ADVERTISED_HOST_NAME it's handled).

- `akka.remote.netty.tcp.port: 6123`

  external port.



Examples
-------------
`run --rm -e "FLINK_CONF={jobmanager.rpc.port: 6001}" -e FLINK_ADVERTISED_HOST_NAME=192.168.1.201 lzaugg/flink-jobmanager:1.0.1_akka-2.4.4`

