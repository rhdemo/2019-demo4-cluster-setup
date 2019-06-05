#!/bin/bash

IMAGE=quay.io/redhatdemo/datagrid
USER=admin
PASS=admin
RESOURCE_DIR=$(dirname "$0")

if [[ ! -z ${DATAGRID_INSTANCES} ]]; then
  INSTANCES=${DATAGRID_INSTANCES}
else
  INSTANCES=${1:-10}
fi

[[ -z "${DATAGRID_CPU}" ]] && { DATAGRID_CPU="1"; }
[[ -z "${DATAGRID_MEMORY}" ]] && { DATAGRID_MEMORY="2048Mi"; }

oc new-project datagrid-demo
oc create -f $RESOURCE_DIR/datagrid-service-custom-xml.yaml
oc create configmap datagrid-config --from-file=$RESOURCE_DIR/config
oc new-app datagrid-service \
  -p APPLICATION_USER=$USER \
  -p APPLICATION_PASSWORD=$PASS \
  -p NUMBER_OF_INSTANCES=$INSTANCES \
  -p TOTAL_CONTAINER_CPU=$DATAGRID_CPU \
  -p TOTAL_CONTAINER_MEM=$DATAGRID_MEMORY \
  -p IMAGE=$IMAGE \
  -e JAVA_OPTS_APPEND="-XX:NativeMemoryTracking=summary -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCDateStamps -XX:+PrintGCCause -XX:+PrintAdaptiveSizePolicy -XX:+PrintPLAB -XX:+PrintGCApplicationConcurrentTime"
oc expose svc/datagrid-service --name=console --port=console
oc expose svc/datagrid-service --name=console-rest --path=/rest --port=http --hostname=$(oc get route console -o=go-template='{{ .spec.host }}')

# Initialise default cache with game config
while [ "$(oc get statefulset datagrid-service -o jsonpath='{.status.readyReplicas}')" != "$INSTANCES" ]; do
    echo "Waiting for statefulset to have $INSTANCES readyReplicas"
    sleep 5
done

GAME_CONFIG_JSON=$(cat "$RESOURCE_DIR/config/game-config.json" | tr -d "\n")
oc exec datagrid-service-0 -- curl -X POST -d "$GAME_CONFIG_JSON" -H application/json http://datagrid-service-0:8080/rest/game/game
