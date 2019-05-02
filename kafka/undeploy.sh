#!/bin/bash

OPERATOR=${KAFKA_OPERATOR:-strimzi}

./10-undeploy-kafka.sh
if [ $OPERATOR == "strimzi" ]; then
    ./20-undeploy-strimzi.sh
elif [ $OPERATOR == "amq-streams" ]; then
    ./20-undeploy-amq-streams.sh
else
    echo "Kafka operator not valid!"
    exit 1
fi