#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi-demo}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function check_openshift_4 {
  if oc api-resources >/dev/null; then
    oc api-resources | grep machineconfigs | grep machineconfiguration.openshift.io > /dev/null 2>&1
  else
    (oc get ns openshift && oc version | tail -1 | grep "v1.12") >/dev/null 2>&1
  fi
}

if check_openshift_4; then
    echo "Detected OpenShift 4 - Installing Strimzi via OLM"

    # reference: https://github.com/operator-framework/operator-marketplace/blob/master/README.md#installing-an-operator-using-marketplace

    sed "s/my-namespace/$NAMESPACE/" $DIR/strimzi/operator-group.yaml > $DIR/strimzi/$NAMESPACE-operator-group.yaml
    sed "s/my-namespace/$NAMESPACE/" $DIR/strimzi/catalog-source-config.yaml > $DIR/strimzi/$NAMESPACE-catalog-source-config.yaml
    sed "s/my-namespace/$NAMESPACE/" $DIR/strimzi/subscription.yaml > $DIR/strimzi/$NAMESPACE-subscription.yaml

    oc apply -f $DIR/strimzi/$NAMESPACE-operator-group.yaml -n $NAMESPACE
    oc apply -f $DIR/strimzi/$NAMESPACE-catalog-source-config.yaml
    oc apply -f $DIR/strimzi/$NAMESPACE-subscription.yaml -n $NAMESPACE

    rm $DIR/strimzi/$NAMESPACE-operator-group.yaml
    rm $DIR/strimzi/$NAMESPACE-catalog-source-config.yaml
    rm $DIR/strimzi/$NAMESPACE-subscription.yaml
else
    echo "OpenShift older than 4 - Installing Strimzi via release"

    # download Strimzi release
    wget https://github.com/strimzi/strimzi-kafka-operator/releases/download/$STRIMZI_VERSION/strimzi-$STRIMZI_VERSION.tar.gz
    mkdir $DIR/strimzi-$STRIMZI_VERSION
    tar xzf strimzi-$STRIMZI_VERSION.tar.gz -C $DIR/strimzi-$STRIMZI_VERSION --strip 1
    rm strimzi-$STRIMZI_VERSION.tar.gz

    sed -i "s/namespace: .*/namespace: $NAMESPACE/" $DIR/strimzi-$STRIMZI_VERSION/install/cluster-operator/*RoleBinding*.yaml

    oc apply -f $DIR/strimzi-$STRIMZI_VERSION/install/cluster-operator -n $NAMESPACE
    oc apply -f $DIR/strimzi-$STRIMZI_VERSION/install/strimzi-admin -n $NAMESPACE

    rm -rf $DIR/strimzi-$STRIMZI_VERSION
fi

echo "Waiting for cluster operator to be ready..."
# this check is done because via OLM, it takes more time to create the deployment
(oc get deployment -n $NAMESPACE | grep strimzi-cluster-operator) >/dev/null 2>&1
while [ $? -ne 0 ]
do
    sleep 2
    (oc get deployment -n $NAMESPACE | grep strimzi-cluster-operator) >/dev/null 2>&1
done
oc rollout status deployment/strimzi-cluster-operator -w -n $NAMESPACE
echo "...cluster operator ready"