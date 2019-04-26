#!/bin/sh

RESOURCE_DIR=$(dirname "$0")


oc new-project machine-history

oc create -f $RESOURCE_DIR/template.yaml
oc new-app machine-history


oc secrets new-sshauth machine-history-deployment-key --ssh-privatekey=id_rsa
oc secrets link builder machine-history-deployment-key

oc new-build https://github.com/stuartwdouglas/quarkus-images.git --context-dir=centos-quarkus-jvm-dev-s2i --name quarkus-jvm-s2i-dev
oc logs -f bc/quarkus-jvm-s2i-dev

oc new-app quarkus-jvm-s2i-dev~git@github.com:rhdemo/2019-demo4-machine-history.git --context-dir=machine-history --name=machine-history-dev
oc set env dc/machine-history-dev QUARKUS_DATASOURCE_URL=jdbc:postgresql://machine-history-postgres-dev:5432/machine_history_dev
oc logs -f bc/machine-history-dev
oc set build-secret --source bc/machine-history-dev machine-history-deployment-key
oc start-build machine-history-dev
oc logs -f bc/machine-history-dev
oc expose svc/machine-history-dev --hostname=machine-history-dev.apps.dev.openshift.redhatkeynote.com