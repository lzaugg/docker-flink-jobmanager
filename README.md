Docker Flink JobManager
============================
Readme inspired by [ches/docker-kafka]:
>   This build intends to provide an operator-friendly  **[Flink]**  deployment suitable for usage in a production Docker environment. It runs one service, no bundled ZooKeeper (for more convenient development, use Docker Compose!).
>   

There exists a build definition for the [Flink] jobmanager and one for the [Flink] taskmanager. The motivation to create this build definition was to get [Flink] running in Docker with multiple docker containers distributed on different machines (e.g. AWS ElasticBeanstalk, AWS ECS, ..).
JobManager and TaskManager are automatically built and available on Docker registry:
- [lzaugg/flink-jobmanager]
- [lzaugg/flink-taskmanager]

The built docker image has (more or less):

- proper signal handling
- docker friendly logging configurations (rolling file appenders, console)
- a minimal footprint (thanks to alpine linux)
- a simple runner without using supervisor, zookeeper, docker compose... just calling java directly (while all those other things are still possible)
- a convenient way to configure flink through environment variables (`FLINK_CONF`,..)
- patched version of Flink 1.1.1 with akka 2.4.9 to support NATed netty with bind hostname and exposed hostname (check tag of docker image!)


Warning / Flink Patching
-------------

This docker image is provided "AS IS", without warranty of any kind. To be able to use Flink with a more docker friendly setup in a NATed environment (e.g. AWS ECS), the following was necessary :

- expose additional akka configuration properties through the Flink configuration mechanism
- update akka version from 2.3.x to 2.4.* (and therefore only Scala 2.11 / Java 8 is supported)

https://github.com/lzaugg/flink/tree/1.1.1_akka-2.4.9 for changes.

The same idea is already documented in https://issues.apache.org/jira/browse/FLINK-2821 (from another person), but I needed it now and for the stable 1.1.1 release of Flink. The configuration options of akka are described in http://doc.akka.io/docs/akka/snapshot/additional/faq.html.

**IMPORTANT**: 

- **this build definition is a moving part as long as missing features are a no go for production use**

- there's no support for Hadoop/YARN
- this README reflects the latest version (check for `-latest` prefix in docker image tags)
- Only S3 shared/distributed filesystem is supported as state backend (hdfs should work also, but some libs will be missing I guess)
- HA mode with zookeeper and S3 as jobmanager state backend should work


Quick Start
-------------

### Example

Example where the hostname of the JobManagers ist set to 192.168.99.100 (reachable from external system).

**JobManager**

```
$ docker run -e FLINK_ADVERTISED_HOST_NAME=192.168.99.100 -p 6123:6123 -p 6124:6124 -p 8081:8081 lzaugg/flink-jobmanager:1.1.1_akka-2.4.9-latest
```

**TaskManager**

```
$ docker run -e FLINK_JOBMANAGER_HOST_NAME=192.168.99.100 lzaugg/flink-taskmanager:1.1.1_akka-2.4.9-latest
```

### Docker Volumes

The container exposes 3 volumes:

- `/flink/logs`: logging
- `/flink/tmp`: tmp directory for taskmanager
- `/flink/blob`: blob directory for taskmanager
- `/flink/state`: state directory for taskmanager

### Docker Ports and Linking

- `6123`: JobManager RPC port
- `6124`: JobManager "BlobManager" port
- `6127`: JobManager Recovery port
- `8081`: JobManager Web Frontend port


Environment
-------------
The most important env variable is:

- **`FLINK_ADVERTISED_HOST_NAME`**
    
    **SHOULD BE SET for JobManager/Taskmanager**. Hostname (or IP address) to be used to connect to this jobmanager/taskmanager from external (e.g. taskmanager -> jobmanager or vice versa). It's the same as setting `FLINK_CONF` to `akka.remote.netty.tcp.hostname: <external-ip>`, just more comfortable. 

Other supported environment variables:

- `FLINK_STATE_URL`

  For convenience: if set, the `state.backend` is set to `filesystem`and `state.backend.fs.checkpointdir` to `$ FLINK_STATE_URL`

- `FLINK_ADVERTISED_PORT`

  Port to be used to connect to this node from external.

- `JVM_ARGS`

  You know, the things like `-Xmx768m`

- `FLINK_ENV_JAVA_OPTS`

  Additional java options for flink, e.g. properties (via -D).

- `FLINK_CONF`

  Accepts any YAML string to configure Flink. Can be used to override flink-conf.yaml parameters. E.g. `{jobmanager.rpc.port: 6120}`. See Configuration section.

  
- `FLINK_JOBMANAGER_HOST_NAME`
    
  **SHOULD BE SET for TaskManager only**. Hostname (or IP address) to be used as connection endpoint for the JobManager. It's the same as setting `FLINK_CONF` to `jobmanager.rpc.address: <job-manager-ip>`, just more comfortable.

- `HADOOP_CORE_CONF`

  For the configuration of `core-site.xml` file.  Accepts any YAML string (will be converted to property/value XML pairs). Take care that it's properly formatted YAML!

- `HADOOP_HDFS_CONF`

  For the configuration of `hdfs-site.xml` file.  Accepts any YAML string (will be converted to property/value XML pairs)


Configuration
--------------

Just the most important configuration properties and their defaults. For a full list see https://ci.apache.org/projects/flink/flink-docs-master/setup/config.html:

### Flink

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

### Hadoop

To use the state backend, support for S3 is included (s3a). Region Frankfurt or Seoul (Signature v4) are **NOT** yet supported (not supported by Flink/Hadoop).

- `fs.s3a.access.key: $AWS_KEY`

- `fs.s3a.secret.key: $AWS_SECRET`


Examples
-------------

```
docker run -it --rm \
    -e FLINK_ADVERTISED_HOST_NAME=myhost \
    -e FLINK_STATE_URL='s3://s3-bucket-flink/checkpoints' \
    -e HADOOP_CORE_CONF='{"fs.s3a.access.key":"huu","fs.s3a.secret.key":"asdf"}' \
    -e FLINK_CONF='{"recovery.zookeeper.storageDir":"s3://s3-bucket-flink/jobmanager","recovery.zookeeper.path.root":"/flink","recovery.zookeeper.quorum":"zookeeperhost:2181","recovery.mode":"zookeeper"}' \
    -p 6123:6123 -p 6124:6124 -p 8081:8081  -p 6127:6127 lzaugg/flink-jobmanager:1.1.3_akka-2.4.12-latest
```


[Flink]: https://flink.apache.org/
[lzaugg/flink-jobmanager]: https://hub.docker.com/r/lzaugg/flink-jobmanager/
[lzaugg/flink-taskmanager]: https://hub.docker.com/r/lzaugg/flink-taskmanager/
[ches/docker-kafka]: https://github.com/ches/docker-kafka
