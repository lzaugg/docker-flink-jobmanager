#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################


# get flink config

bin=$FLINK_HOME/bin
                                                                                                                                                                                                                                                                
. "$bin"/config.sh

if [ "$FLINK_IDENT_STRING" = "" ]; then
        FLINK_IDENT_STRING="$USER"
fi

if [ "${FLINK_CLASS_TO_RUN}x" = "x" ]; then
	echo "ENV FLINK_CLASS_TO_RUN missing!"
	exit 1
fi

echo "" >> $FLINK_CONF_DIR/flink-conf.yaml



if [ ! "${FLINK_JOBMANAGER_HOST_NAME}x" = "x" ]; then
	echo "jobmanager.rpc.address: $FLINK_JOBMANAGER_HOST_NAME" >> $FLINK_CONF_DIR/flink-conf.yaml
fi

if [ ! "${FLINK_ADVERTISED_PORT}x" = "x" ]; then
	echo "akka.remote.netty.tcp.port: $FLINK_ADVERTISED_PORT" >> $FLINK_CONF_DIR/flink-conf.yaml
fi

if [ ! "${FLINK_ADVERTISED_HOST_NAME}x" = "x" ]; then
	FLINK_ADVERTISED_IP=$(getent hosts $FLINK_ADVERTISED_HOST_NAME | awk '{ print $1 }')
	if [ ! "$?" = "0" ]; then
		echo "couldn't resolve FLINK_ADVERTISED_HOST_NAME propertly. Invalid hostname or malfunctioning DNS."
		exit 1
	fi

	echo "akka.remote.netty.tcp.hostname: $FLINK_ADVERTISED_IP" >> $FLINK_CONF_DIR/flink-conf.yaml
fi

if [ ! "${FLINK_CONF}x" = "x" ]; then
	echo "using custom FLINK_CONF: ${FLINK_CONF}"
	cp $FLINK_CONF_DIR/flink-conf.yaml /tmp/flink-conf-orig.yaml
	echo "$FLINK_CONF" > /tmp/flink-conf-env.yaml
	# merge files. flink configuration is not really YAML compliant, therefore we need to remove '"'' and '---'
	ruby $bin/docker_merge-yml-file.rb /tmp/flink-conf-orig.yaml /tmp/flink-conf-env.yaml | grep -v '\---'|sed -e 's/"//g' > /tmp/flink-conf.yaml
	if [ ! "$?" = "0" ]; then
		echo "illegal FLINK_CONF env!"
		exit 1
	else
		cp /tmp/flink-conf.yaml $FLINK_CONF_DIR/flink-conf.yaml
	fi
fi
echo "================================"
echo "Flink configuration:"
echo "================================"
cat $FLINK_CONF_DIR/flink-conf.yaml
echo ""
echo "================================"

CC_CLASSPATH=`constructFlinkClassPath`

log=$FLINK_LOG_DIR/flink-$FLINK_IDENT_STRING-client-$HOSTNAME.log
log_setting=(-Dlog.file="$log" -Dlog4j.configuration=file:"$FLINK_CONF_DIR"/log4j-docker.properties -Dlogback.configurationFile=file:"$FLINK_CONF_DIR"/logback-docker.xml)

export FLINK_ROOT_DIR
export FLINK_CONF_DIR



# Add HADOOP_CLASSPATH to allow the usage of Hadoop file systems
exec $JAVA_RUN $JVM_ARGS ${FLINK_ENV_JAVA_OPTS} "${log_setting[@]}" -classpath "`manglePathList "$CC_CLASSPATH:$INTERNAL_HADOOP_CLASSPATHS"`" ${FLINK_CLASS_TO_RUN} "$@"