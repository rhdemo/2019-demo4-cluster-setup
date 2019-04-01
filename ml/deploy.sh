#!/usr/bin/env bash

#set -x

DWNLD_PATH="ml/.tmp"

mkdir -p ${DWNLD_PATH}
curl -o ${DWNLD_PATH}/install.sh "https://raw.githubusercontent.com/rhdemo/2019-demo4-ai/master/openshift/install.sh?time=`date +%N`"

PROJECT=tf-demo
GIT_REF="master"

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}
GIT_REF=${GIT_REF} bash ${DWNLD_PATH}/install.sh


oc process s3-config -p AWS_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID} -p AWS_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY} | oc apply -f -
oc process jupyter-notebook-workspace-tensorflow | oc apply -f -
