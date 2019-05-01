#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi-demo}

echo "Scaling down strimzi-console-server to 0..."
oc scale deployment strimzi-console-server --replicas=0 -n $NAMESPACE

echo "Scaling up strimzi-console-server to 1..."
oc scale deployment strimzi-console-server --replicas=1 -n $NAMESPACE

echo "Waiting for console server to be ready..."
oc rollout status deployment/strimzi-console-server -w -n $NAMESPACE
echo "...console server ready"

echo "Scaling down strimzi-console to 0..."
oc scale deployment strimzi-console --replicas=0 -n $NAMESPACE

echo "Scaling up strimzi-console to 1..."
oc scale deployment strimzi-console --replicas=1 -n $NAMESPACE

echo "Waiting for console to be ready..."
oc rollout status deployment/strimzi-console -w -n $NAMESPACE
echo "...console ready"