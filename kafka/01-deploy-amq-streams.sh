#!/bin/bash

NAMESPACE=${KAFKA_NAMESPACE:-strimzi-demo}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function check_openshift_4 {
  if oc api-resources >/dev/null; then
    oc api-resources | grep machineconfigs | grep machineconfiguration.openshift.io > /dev/null 2>&1
  else
    (oc get ns openshift && oc version | tail -1 | grep "v1.12") >/dev/null 2>&1
  fi
}

if check_openshift_4; then
    echo "Detected OpenShift 4 - Installing AMQ Streams via OLM"

    # reference: https://github.com/operator-framework/operator-marketplace/blob/master/README.md#installing-an-operator-using-marketplace

    sed "s/my-namespace/$NAMESPACE/" $DIR/amq-streams/operator-group.yaml > $DIR/amq-streams/$NAMESPACE-operator-group.yaml
    sed "s/my-namespace/$NAMESPACE/" $DIR/amq-streams/catalog-source-config.yaml > $DIR/amq-streams/$NAMESPACE-catalog-source-config.yaml
    sed "s/my-namespace/$NAMESPACE/" $DIR/amq-streams/subscription.yaml > $DIR/amq-streams/$NAMESPACE-subscription.yaml

    oc apply -f $DIR/amq-streams/$NAMESPACE-operator-group.yaml -n $NAMESPACE
    oc apply -f $DIR/amq-streams/$NAMESPACE-catalog-source-config.yaml
    oc apply -f $DIR/amq-streams/$NAMESPACE-subscription.yaml -n $NAMESPACE

    rm $DIR/amq-streams/$NAMESPACE-operator-group.yaml
    rm $DIR/amq-streams/$NAMESPACE-catalog-source-config.yaml
    rm $DIR/amq-streams/$NAMESPACE-subscription.yaml
else
    echo "OpenShift older than 4 - Cancelling AMQ Streams installation"
    exit 1
fi

echo "Waiting for cluster operator to be ready..."
# this check is done because via OLM, it takes more time to create the deployment
(oc get deployment -n $NAMESPACE | grep amq-streams-cluster-operator) >/dev/null 2>&1
while [ $? -ne 0 ]
do
    sleep 2
    (oc get deployment -n $NAMESPACE | grep amq-streams-cluster-operator) >/dev/null 2>&1
done
oc rollout status deployment/amq-streams-cluster-operator -w -n $NAMESPACE
echo "...cluster operator ready"