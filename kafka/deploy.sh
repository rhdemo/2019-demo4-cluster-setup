#!/bin/bash

echo "STRIMZI_VERSION=" $STRIMZI_VERSION
echo "STRIMZI_NAMESPACE=" $STRIMZI_NAMESPACE
echo "STRIMZI_CLUSTER=" $STRIMZI_CLUSTER

oc project $STRIMZI_NAMESPACE 2> /dev/null || oc new-project $STRIMZI_NAMESPACE

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "DEPLOYING KAFKA CLUSTER WITH STRIMZI ..."

# cluster deployment
$DIR/01-deploy-strimzi.sh
$DIR/02-deploy-kafka.sh
$DIR/03-deploy-console-server.sh
$DIR/04-deploy-console.sh
$DIR/05-deploy-monitoring.sh
$DIR/06-deploy-topics.sh

echo ""
echo "... KAFKA CLUSTER DEPLOYED!"
