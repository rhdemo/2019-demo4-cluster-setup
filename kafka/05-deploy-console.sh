#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sed "s/my-cluster/$CLUSTER/" $DIR/console/020-Deployment-strimzi-console.yaml > $DIR/console/$CLUSTER-020-Deployment-strimzi-console.yaml

oc apply -f $DIR/console -n $NAMESPACE
oc expose service/strimzi-console -n $NAMESPACE

echo "Waiting for console to be ready..."
oc rollout status deployment/strimzi-console -w -n $NAMESPACE
echo "...console ready"

rm $DIR/console/$CLUSTER-020-Deployment-strimzi-console.yaml