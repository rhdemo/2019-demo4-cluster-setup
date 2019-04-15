#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=syndesis

oc new-project ${TARGET_PROJECT} | true

#
# Patch syndesis-server-config
#

#
# Restart syndesis-ui
#
#oc delete pod -l syndesis.io/component=syndesis-ui
