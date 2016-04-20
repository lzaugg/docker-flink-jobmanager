FROM alpine:3.3 
MAINTAINER l.zaugg@mypi.ch

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --update \
    curl openjdk8 bash ruby procps \
    && rm /var/cache/apk/*

ENV FLINK_VERSION 1.0.1_akka-2.4.4
ENV FLINK_HADOOP_VERSION hadoop27
ENV FLINK_SCALA_VERSION scala_2.11
ENV FLINK_CLASS_TO_RUN org.apache.flink.runtime.jobmanager.JobManager
ENV FLINK_HOME /opt/flink

RUN mkdir -p /opt/

RUN curl https://s3.eu-central-1.amazonaws.com/flink-1.0.1-akka-2.4.4/flink-1.0.1_akka-2.4.4.tar.gz  | tar -C /opt/ -xz | ln -s /opt/flink-${FLINK_VERSION}/ ${FLINK_HOME}

ADD docker_flink-run.sh ${FLINK_HOME}/bin
ADD conf/log4j-docker.properties ${FLINK_HOME}/conf
ADD conf/logback-docker.xml ${FLINK_HOME}/conf
ADD docker_merge-yml-file.rb ${FLINK_HOME}/bin

RUN mkdir -p /opt/flink/log
VOLUME /opt/flink/log

USER root

ENTRYPOINT [ "/opt/flink/bin/docker_flink-run.sh", "--configDir", "/opt/flink/conf/"]

CMD ["--executionMode", "cluster"]
EXPOSE 6123 8080 8081
