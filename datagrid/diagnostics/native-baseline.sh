#!/usr/bin/env bash

set -e

DIAGNOSTICS_DIR=$(dirname "$0")
source ./$DIAGNOSTICS_DIR/config.sh

# Quick check
oc project

for ((i = 0; i < ${NUM_INSTANCES}; i++)); do
    pod="datagrid-service-${i}"
    echo "Native baseline for: ${pod}"

    pid=$(oc exec ${pod} -- jps | grep jboss-modules.jar | awk '{print $1}')

    oc exec ${pod} -- jcmd ${pid} VM.native_memory baseline
done
