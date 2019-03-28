#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}
CLUSTER=${STRIMZI_CLUSTER:-my-cluster}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

sed "s/my-cluster/$CLUSTER/" $DIR/cluster/kafka-persistent-with-metrics.yaml > $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml

oc apply -f $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml -n $NAMESPACE

# delay for allowing cluster operator to create the first Zookeeper statefulset
sleep 5

zkReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.zookeeper.replicas}" -n $NAMESPACE)
echo "Waiting for Zookeeper cluster to be ready..."
readyReplicas="0"
while [ "$readyReplicas" != "$zkReplicas" ]
do
    sleep 2
    readyReplicas=$(oc get statefulsets $CLUSTER-zookeeper -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
done
echo "...Zookeeper cluster ready"

kReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.kafka.replicas}" -n $NAMESPACE)
echo "Waiting for Kafka cluster to be ready..."
readyReplicas="0"
while [ "$readyReplicas" != "$kReplicas" ]
do
    sleep 2
    readyReplicas=$(oc get statefulsets $CLUSTER-kafka -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
done
echo "...Kafka cluster ready"

echo "Waiting for entity operator to be ready..."
oc rollout status deployment/$CLUSTER-entity-operator -w -n $NAMESPACE
echo "...entity operator ready"

rm $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml