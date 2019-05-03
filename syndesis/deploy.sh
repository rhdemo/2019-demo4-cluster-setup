#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=${1:-syndesis}

# Using a recent tag, not master, so the images don't get redeployed at each commit
SYNDESIS_BASE_TAG=1.6.4

oc new-project ${TARGET_PROJECT} | true

#
# Install 
#
bash $dir/deploy_camel_k.sh ${TARGET_PROJECT}
bash $dir/deploy_syndesis.sh ${TARGET_PROJECT}
bash $dir/deploy_services.sh ${TARGET_PROJECT}
bash $dir/deploy_sources.sh ${TARGET_PROJECT}
bash $dir/patch_sources_deployment.sh ${TARGET_PROJECT}
