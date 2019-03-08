#!/usr/bin/env bash

#set -x

DWNLD_PATH="ml/.tmp"

mkdir -p ${DWNLD_PATH}
curl -o ${DWNLD_PATH}/install.sh https://raw.githubusercontent.com/vpavlin/odh-tensorflow-jobs/knative/openshift/install.sh

PROJECT=tf-demo
GIT_REF=knative

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}
GIT_REF=${GIT_REF} bash ${DWNLD_PATH}/install.sh


oc process odh-config -p S3_ENDPOINT_URL=http://ceph-nano:8000 -p AWS_ACCESS_KEY_ID=foo -p AWS_SECRET_ACCESS_KEY=bar | oc apply -f -
oc process jupyter-notebook-workspace-tensorflow | oc apply -f -
