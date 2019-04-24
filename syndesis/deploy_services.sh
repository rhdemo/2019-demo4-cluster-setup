#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=${1:-syndesis}
# TODO before the summit, use a tag, not master
oc new-project ${TARGET_PROJECT} | true

oc apply -n ${TARGET_PROJECT} -f $dir/resources/damage-service.yaml
oc apply -n ${TARGET_PROJECT} -f $dir/resources/damage-service-test.yaml
oc apply -n ${TARGET_PROJECT} -f $dir/resources/camel-q.yaml
#oc apply -n ${TARGET_PROJECT} -f $dir/resources/load.yaml
