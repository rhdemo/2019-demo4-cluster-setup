#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=syndesis

oc new-project ${TARGET_PROJECT} | true

#
# Patch syndesis-server-config
#
loop oc get cm syndesis-server-config -n $TARGET_PROJECT -o yaml > tmp_config.yaml
if [ $(grep "integration: camel-k" tmp_config.yaml | wc -l) -eq 0 ]; then
    cat tmp_config.yaml | sed 's/controllers:/controllers:\\n  integration: camel-k/' > camelk_config.yaml
    loop oc replace --force -n ${TARGET_PROJECT} -f camelk_config.yaml
    rm camelk_config.yaml
fi
rm tmp_config.yaml

#
# Restart syndesis-ui
#
#oc delete pod -l syndesis.io/component=syndesis-ui
