#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sed "s/my-cluster/$CLUSTER/" $DIR/cluster/kafka-topics.yaml > $DIR/cluster/$CLUSTER-kafka-topics.yaml

oc apply -f $DIR/cluster/$CLUSTER-kafka-topics.yaml -n $NAMESPACE

rm $DIR/cluster/$CLUSTER-kafka-topics.yaml