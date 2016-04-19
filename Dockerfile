FROM alpine:3.3 
MAINTAINER l.zaugg@mypi.ch

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --update \
    curl openjdk8 bash ruby procps \
    && rm /var/cache/apk/*

ENV FLINK_VERSION 1.0.1
ENV FLINK_HADOOP_VERSION hadoop27
ENV FLINK_SCALA_VERSION scala_2.11
ENV FLINK_CLASS_TO_RUN org.apache.flink.runtime.jobmanager.JobManager
ENV FLINK_HOME /opt/flink

RUN mkdir -p /opt/
RUN curl http://www.mirrorservice.org/sites/ftp.apache.org/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-${FLINK_HADOOP_VERSION}-${FLINK_SCALA_VERSION}.tgz  | tar -C /opt/ -xz | ln -s /opt/flink-${FLINK_VERSION}/ ${FLINK_HOME}

ADD docker_flink-run.sh ${FLINK_HOME}/bin
ADD conf/log4j-docker.properties ${FLINK_HOME}/conf
ADD conf/logback-docker.xml ${FLINK_HOME}/conf
ADD docker_merge-yml-file.rb ${FLINK_HOME}/bin

RUN mkdir -p /opt/flink/log
VOLUME /opt/flink/log

USER root

ENTRYPOINT [ "/opt/flink/bin/docker_flink-run.sh" ]

CMD ["--executionMode", "cluster", "--configDir", "/opt/flink/conf/"]
EXPOSE 6123 8080 8081