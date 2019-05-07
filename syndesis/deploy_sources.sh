#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=${1:-syndesis}
# TODO before the summit, use a tag, not master
oc new-project ${TARGET_PROJECT} | true

#
# knative sources
#
#oc apply -n ${TARGET_PROJECT} -f $dir/resources/kafka-source.yaml
oc apply -n ${TARGET_PROJECT} -f $dir/resources/kafka-source-raw.yaml
oc apply -n ${TARGET_PROJECT} -f $dir/resources/kafka-source-game.yaml
