#!/usr/bin/env bash

set -ex

TARGET_PROJECT=camel-k
oc new-project ${TARGET_PROJECT} | true

#
# Create some Volume Claims
#
oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
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

oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
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