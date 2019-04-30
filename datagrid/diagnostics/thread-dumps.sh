#!/usr/bin/env bash

set -e

source ./config.sh

# Quick check
oc project

for ((i = 0; i < ${NUM_INSTANCES}; i++)); do
    pod="datagrid-service-${i}"
    echo "Diagnostics for: ${pod}"

    pid=$(oc exec ${pod} -- jps | grep jboss-modules.jar | awk '{print $1}')

    echo "Generate thread dump"
    oc exec ${pod} -- kill -3 ${pid}
done
