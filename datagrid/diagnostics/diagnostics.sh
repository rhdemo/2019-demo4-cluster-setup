#!/usr/bin/env bash

set -e

source ./config.sh

# Quick check
oc project

DIAGNOSTICS_DIR=$(mktemp -d -t datagrid-)
echo "Diagnostics directory: ${DIAGNOSTICS_DIR}"

for ((i = 0; i < ${NUM_INSTANCES}; i++)); do
    pod="datagrid-service-${i}"
    echo "Diagnostics for: ${pod}"

    podDir=${DIAGNOSTICS_DIR}/${pod}
    mkdir ${podDir}

    pid=$(oc exec ${pod} -- jps | grep jboss-modules.jar | awk '{print $1}')

    echo "Copy GC log"
    oc rsync "${pod}:/opt/datagrid/standalone/log" ${podDir}
    cat ${podDir}/log/gc.log* > ${podDir}/gc.log

    echo "Generate a heap dump and copy locally"
    oc exec ${pod} -- rm heap.bin || true
    oc exec ${pod} -- jmap -dump:format=b,file=heap.bin ${pid}
    oc rsync "${pod}:/home/jboss/heap.bin" ${podDir}

    echo "Generate thread dump and copy log"
    oc exec ${pod} -- kill -3 ${pid}
    oc logs ${pod} > ${podDir}/${pod}.log
done
