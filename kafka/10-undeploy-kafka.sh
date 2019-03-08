#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}

# delete Kafka topics
oc delete kafkatopic data-filtered -n $NAMESPACE
oc delete kafkatopic camel-output -n $NAMESPACE
# delete Kafka cluster
oc delete kafka $CLUSTER -n $NAMESPACE