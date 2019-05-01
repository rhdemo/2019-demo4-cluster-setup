#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi-demo}
CLUSTER=${STRIMZI_CLUSTER:-demo2019}

# delete Kafka topics
oc delete kafkatopic sensorstream-ai -n $NAMESPACE
oc delete kafkatopic sensorstream-raw -n $NAMESPACE
# delete Kafka cluster
oc delete kafka $CLUSTER -n $NAMESPACE