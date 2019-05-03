#!/bin/bash

OPERATOR=${KAFKA_OPERATOR:-strimzi}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "UNDEPLOYING KAFKA CLUSTER..."
echo ""

$DIR/10-undeploy-kafka.sh
if [ $OPERATOR == "strimzi" ]; then
    $DIR/20-undeploy-strimzi.sh
elif [ $OPERATOR == "amq-streams" ]; then
    $DIR/20-undeploy-amq-streams.sh
else
    echo "Kafka operator not valid!"
    exit 1
fi

echo ""
echo "... KAFKA CLUSTER UNDEPLOYED!"