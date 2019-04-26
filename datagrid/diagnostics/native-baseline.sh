#!/usr/bin/env bash

set -e

# Quick check
oc project

declare -a PodArray=("datagrid-service-0" "datagrid-service-1" "datagrid-service-2" "datagrid-service-3")

for pod in ${PodArray[@]}; do
    echo "Native baseline for: ${pod}"

    pid=$(oc exec ${pod} -- jps | grep jboss-modules.jar | awk '{print $1}')

    oc exec ${pod} -- jcmd ${pid} VM.native_memory baseline
done
