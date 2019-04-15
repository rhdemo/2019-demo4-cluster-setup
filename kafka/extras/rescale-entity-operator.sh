#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}

echo "Scaling down entity operator to 0..."
oc scale deployment $CLUSTER-entity-operator --replicas=0 -n $NAMESPACE

echo "Scaling up entity operator to 1..."
oc scale deployment $CLUSTER-entity-operator --replicas=1 -n $NAMESPACE

echo "Waiting for entity operator to be ready..."
oc rollout status deployment/$CLUSTER-entity-operator -w -n $NAMESPACE
echo "...entity operator ready"