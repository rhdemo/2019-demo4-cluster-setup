#!/bin/bash

echo "KAFKA_OPERATOR=" $KAFKA_OPERATOR
echo "KAFKA_OPERATOR_VERSION=" $KAFKA_OPERATOR_VERSION
echo "KAFKA_NAMESPACE=" $KAFKA_NAMESPACE
echo "KAFKA_CLUSTER=" $KAFKA_CLUSTER

oc project $KAFKA_NAMESPACE 2> /dev/null || oc new-project $KAFKA_NAMESPACE

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "DEPLOYING KAFKA CLUSTER..."
echo ""

# cluster deployment
if [ $KAFKA_OPERATOR == "strimzi" ]; then
    $DIR/01-deploy-strimzi.sh
elif [ $KAFKA_OPERATOR == "amq-streams" ]; then
    $DIR/01-deploy-amq-streams.sh
else
    echo "Kafka operator not valid!"
    exit 1
fi
$DIR/02-deploy-kafka.sh
$DIR/03-deploy-console-server.sh
$DIR/04-deploy-console.sh
$DIR/05-deploy-monitoring.sh
$DIR/06-deploy-topics.sh

echo ""
echo "... KAFKA CLUSTER DEPLOYED!"
