#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=${1:-syndesis}

oc new-project ${TARGET_PROJECT} | true

#
# Patch syndesis-server-config
#

oc get configmap syndesis-server-config -o yaml \
    > /tmp/syndesis-server-config.yml

cat /tmp/syndesis-server-config.yml \
    | yq r - 'data[application.yml]' \
    | yq w - controllers.dblogging.enabled false \
    | yq w - controllers.integration camel-k \
    | yq w - controllers.camelk.environment.DATAGRID_SERVICE_HOST datagrid-service.datagrid-demo.svc.cluster.local \
    | yq w - controllers.camelk.environment.DATAGRID_SERVICE_PORT 11222 \
    | yq w - controllers.camelk.environment.DATAGRID_CACHE_NAME camel-salesforce \
    | yq w - resource.update.controller.enabled false \
    > /tmp/application.yml

oc create cm syndesis-server-config-x --from-file=/tmp/application.yml --dry-run -o yaml \
    | yq d - apiVersion \
    | yq d - kind \
    | yq d - metadata \
    > /tmp/syndesis-server-config-patch.yaml 

yq m -x /tmp/syndesis-server-config.yml /tmp/syndesis-server-config-patch.yaml \
    | oc apply -f -

rm /tmp/application.yml
rm /tmp/syndesis-server-config-patch.yaml 

