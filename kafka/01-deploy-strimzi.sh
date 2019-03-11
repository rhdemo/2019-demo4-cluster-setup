#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# download Strimzi release
wget https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-$STRIMZI_VERSION.tar.gz
mkdir $DIR/strimzi
tar xzf strimzi-$STRIMZI_VERSION.tar.gz -C $DIR/strimzi --strip 1
rm strimzi-$STRIMZI_VERSION.tar.gz

sed -i "s/namespace: .*/namespace: $NAMESPACE/" $DIR/strimzi/install/cluster-operator/*RoleBinding*.yaml

oc apply -f $DIR/strimzi/install/cluster-operator -n $NAMESPACE
oc apply -f $DIR/strimzi/install/strimzi-admin -n $NAMESPACE

echo "Waiting for cluster operator to be ready..."
oc rollout status deployment/strimzi-cluster-operator -w -n $NAMESPACE
echo "...cluster operator ready"

rm -rf $DIR/strimzi