#!/usr/bin/env bash

set -ex

TARGET_PROJECT=syndesis
oc new-project ${TARGET_PROJECT} | true

#
# Create some Volume Claims
#
(oc create -n ${TARGET_PROJECT} -f - || true) <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: syndesis-db
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2
EOF

(oc create -n ${TARGET_PROJECT} -f - || true) <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: syndesis-meta
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2
EOF

#
# Install the CRD.
#
oc replace --force -n openshift -f https://raw.githubusercontent.com/syndesisio/syndesis/master/install/operator/deploy/syndesis-crd.yml

#
# Create the syndesis operator Deploytment Config, and create a Syndesis resource.
#
oc replace --force -n ${TARGET_PROJECT} -f https://raw.githubusercontent.com/syndesisio/syndesis/master/install/operator/deploy/syndesis-operator.yml 
oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
apiVersion: "syndesis.io/v1alpha1"
kind: "Syndesis"
metadata:
  name: "default"
spec:
  demoData: false
  integration:
    limit: 50
    stateCheckInterval: 60
  registry: docker.io
EOF

#
# Pickup some bug fixes by patching the image streams.
#
loop() {
    while true ; do
        if "$@" ; then
            break
        fi
        sleep 1
    done
}


loop oc patch -n ${TARGET_PROJECT} is syndesis-server --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/hchirino/syndesis-server:latest"}]'
loop oc patch -n ${TARGET_PROJECT} is oauth-proxy --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/openshift/origin-oauth-proxy:latest"}]'
