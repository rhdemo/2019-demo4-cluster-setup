#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}

# delete Kafka topics
oc delete kafkatopic sensorstream-ai -n $NAMESPACE
oc delete kafkatopic sensorstream-raw -n $NAMESPACE
# delete Kafka cluster
oc delete kafka $CLUSTER -n $NAMESPACE