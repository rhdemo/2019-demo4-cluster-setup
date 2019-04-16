#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=syndesis

oc new-project ${TARGET_PROJECT} | true

#
# Patch syndesis-ui-config
#
oc get configmap syndesis-ui-config -o jsonpath={.data."config\.json"} \
  | jq '.branding += { "logoWhiteBg": "", "logoDarkBg": "", "iconWhiteBg": "assets/images/FuseOnlineLogo_Black.svg", "iconDarkBg": "assets/images/FuseOnlineLogo_White.svg", "appName": "Ignite", "productBuild": true }' \
  > /tmp/config.json

oc get configmap syndesis-ui-config --export -o json \
  | jq ". * $(oc create configmap syndesis-ui-config --from-file /tmp/config.json --dry-run -o json)" \
  | oc apply -f -

rm -f /tmp/syndesis-ui-config.json
rm -f /tmp/config.json

#
# Restart syndesis-ui
#
#oc delete pod -l syndesis.io/component=syndesis-ui
