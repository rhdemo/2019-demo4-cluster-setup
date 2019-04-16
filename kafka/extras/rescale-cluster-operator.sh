#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}

echo "Scaling down cluster operator to 0..."
oc scale deployment strimzi-cluster-operator --replicas=0 -n $NAMESPACE

echo "Scaling up cluster operator to 1..."
oc scale deployment strimzi-cluster-operator --replicas=1 -n $NAMESPACE

echo "Waiting for cluster operator to be ready..."
oc rollout status deployment/strimzi-cluster-operator -w -n $NAMESPACE
echo "...cluster operator ready"