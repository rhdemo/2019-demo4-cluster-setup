#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sed -i "s/namespace: .*/namespace: $NAMESPACE/" $DIR/strimzi/install/cluster-operator/*RoleBinding*.yaml

oc apply -f $DIR/strimzi/install/cluster-operator -n $NAMESPACE
oc apply -f $DIR/strimzi/install/strimzi-admin -n $NAMESPACE

echo "Waiting for cluster operator to be ready..."
oc rollout status deployment/strimzi-cluster-operator -w -n $NAMESPACE
echo "...cluster operator ready"