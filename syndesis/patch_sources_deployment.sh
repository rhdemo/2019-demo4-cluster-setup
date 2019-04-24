#!/bin/bash

TARGET_PROJECT=${1:-syndesis}

# KafkaSource for hard share from sensorstream-raw topic
KAFKA_SOURCE=$(oc get deployment -n $TARGET_PROJECT -l knative-eventing-source-name=sensorstream-source-raw -o jsonpath='{.items[0].metadata.name}{"\n"}')
# check that the deployment is ready from the installation
echo "Checking that $KAFKA_SOURCE deployment is ready..."
oc rollout status deployment/$KAFKA_SOURCE -w -n $TARGET_PROJECT
echo "...$KAFKA_SOURCE deployment ready"

# patching and waiting for the related pod running
oc patch deployment $KAFKA_SOURCE --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {"requests": {"memory": "512Mi", "cpu": "250m"}, "limits": {"memory": "512Mi", "cpu": "250m"}}}]' -n $TARGET_PROJECT

echo "Waiting for $KAFKA_SOURCE deployment to be ready..."
oc rollout status deployment/$KAFKA_SOURCE -w -n $TARGET_PROJECT
echo "...$KAFKA_SOURCE deployment ready"

# KafkaSource for the game from sensorstream-ai topic
KAFKA_SOURCE=$(oc get deployment -n $TARGET_PROJECT -l knative-eventing-source-name=sensorstream-source -o jsonpath='{.items[0].metadata.name}{"\n"}')
# check that the deployment is ready from the installation
echo "Checking that $KAFKA_SOURCE deployment is ready..."
oc rollout status deployment/$KAFKA_SOURCE -w -n $TARGET_PROJECT
echo "...$KAFKA_SOURCE deployment ready"

# patching and waiting for the related pod running
oc patch deployment $KAFKA_SOURCE --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {"requests": {"memory": "512Mi", "cpu": "250m"}, "limits": {"memory": "512Mi", "cpu": "250m"}}}]' -n $TARGET_PROJECT

echo "Waiting for $KAFKA_SOURCE deployment to be ready..."
oc rollout status deployment/$KAFKA_SOURCE -w -n $TARGET_PROJECT
echo "...$KAFKA_SOURCE deployment ready"