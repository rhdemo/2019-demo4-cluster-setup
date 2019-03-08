#!/bin/bash

NAMESPACE=${STRIMZI_NAMESPACE:-strimzi}

# deleting "all" Strimzi resources
oc delete all -l app=strimzi -n $NAMESPACE

# deleting CRDs, service account, cluster roles, cluster role bindings, 
oc delete configmap -l app=strimzi -n $NAMESPACE
oc delete crd -l app=strimzi
oc delete serviceaccount -l app=strimzi -n $NAMESPACE
oc delete clusterrole -l app=strimzi
oc delete clusterrolebinding -l app=strimzi
oc delete rolebinding -l app=strimzi -n $NAMESPACE