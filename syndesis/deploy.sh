#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=syndesis
# Using a recent tag, not master, so the images don't get redeployed at each commit
SYNDESIS_BASE_TAG=1.6.4

oc new-project ${TARGET_PROJECT} | true

#
# Install 
#
bash $dir/deploy_camel_k.sh
bash $dir/deploy_syndesis.sh
bash $dir/deploy_syndesis_ui_config.sh
bash $dir/deploy_syndesis_seerver_config.sh
bash $dir/deploy_sources.sh
bash $dir/deploy_services.sh
