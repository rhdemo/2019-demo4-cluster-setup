#!/bin/bash
PROJECT_NAMESPACE=optaplanner-demo
OPTAPLANNER_APP_NAME=optaplanner-demo
RESOURCE_DIR=$(dirname "$0")

oc project ${PROJECT_NAMESPACE} 2> /dev/null || oc new-project ${PROJECT_NAMESPACE}
oc create -f $RESOURCE_DIR/optaplanner-demo-template.yaml
oc new-app --template="${PROJECT_NAMESPACE}/optaplanner-demo"
