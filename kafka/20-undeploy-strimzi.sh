#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi-demo}

function check_openshift_4 {
  if oc api-resources >/dev/null; then
    oc api-resources | grep machineconfigs | grep machineconfiguration.openshift.io > /dev/null 2>&1
  else
    (oc get ns openshift && oc version | tail -1 | grep "v1.12") >/dev/null 2>&1
  fi
}

if check_openshift_4; then
    # uninstall operator
    oc delete subscriptions.operators.coreos.com strimzi-kafka-operator -n $NAMESPACE
    oc delete clusterserviceversion strimzi-cluster-operator.v0.11.1 -n $NAMESPACE
    oc delete catalogsourceconfig installed-community-$NAMESPACE -n openshift-marketplace
    oc delete operatorgroup strimzi-kafka-operator -n $NAMESPACE
fi

# deleting "all" Strimzi resources
oc delete all -l app=strimzi -n $NAMESPACE

# deleting CRDs, service account, cluster roles, cluster role bindings, 
oc delete configmap -l app=strimzi -n $NAMESPACE
oc delete crd -l app=strimzi
oc delete serviceaccount -l app=strimzi -n $NAMESPACE
oc delete clusterrole -l app=strimzi
oc delete clusterrolebinding -l app=strimzi
oc delete rolebinding -l app=strimzi -n $NAMESPACE