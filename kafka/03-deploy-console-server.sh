#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi-demo}
CLUSTER=${STRIMZI_CLUSTER:-demo2019}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sed "s/my-cluster/$CLUSTER/" $DIR/console-server/020-Deployment-strimzi-console-server.yaml > $DIR/console-server/$CLUSTER-020-Deployment-strimzi-console-server.yaml

oc apply -f $DIR/console-server -n $NAMESPACE

echo "Waiting for console server to be ready..."
oc rollout status deployment/strimzi-console-server -w -n $NAMESPACE
echo "...console server ready"

rm $DIR/console-server/$CLUSTER-020-Deployment-strimzi-console-server.yaml