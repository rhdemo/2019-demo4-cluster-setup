#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=syndesis
# Using a recent tag, not master, so the images don't get redeployed at each commit
SYNDESIS_BASE_TAG=1.7.1-20190319

oc new-project ${TARGET_PROJECT} | true


#
# Install Camel K first
#
bash $dir/deploy_camel_k.sh $TARGET_PROJECT


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
# Initialize the DB volume to overcome the issue with volume permissions
#
oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: db-initializer
spec:
  restartPolicy: OnFailure
  containers:
  - name: myapp-container
    image: busybox
    command: ['sh', '-c', 'echo DB Volume Initialized']
  initContainers:
  - command:
    - chmod
    - "777"
    - /var/lib/pgsql/data
    image: busybox
    imagePullPolicy: IfNotPresent
    name: volume-permission
    volumeMounts:
    - mountPath: /var/lib/pgsql/data
      name: syndesis-db-data
  volumes:
  - name: syndesis-db-data
    persistentVolumeClaim:
      claimName: syndesis-db
EOF

#
# Wait for the hack pod to reach the Succeeded phase
#
while true ; do
    if [ "$(oc get pod db-initializer -n $TARGET_PROJECT -o=jsonpath='{.status.phase}')" = "Succeeded" ]; then
        break
    fi
    sleep 1
done

#
# Install the CRD (don't replace if already present, otherwise syndesis will be erased from all namespaces where it's installed).
#
oc create -n openshift -f https://raw.githubusercontent.com/syndesisio/syndesis/$SYNDESIS_BASE_TAG/install/operator/deploy/syndesis-crd.yml | true

#
# Create the syndesis operator Deployment Config, and create a Syndesis resource.
#
oc replace --force -n ${TARGET_PROJECT} -f https://raw.githubusercontent.com/syndesisio/syndesis/$SYNDESIS_BASE_TAG/install/operator/deploy/syndesis-operator.yml
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
# Wait for the installation to reach the Starting phase (resources created)
#
wait_for "Starting" oc get syndesis default -n $TARGET_PROJECT -o=jsonpath="{.status.phase}"

#
# Configure server to use Camel K engine
#
loop oc get cm syndesis-server-config -n $TARGET_PROJECT -o yaml > tmp_config.yaml
if [ $(grep "integration: camel-k" tmp_config.yaml | wc -l) -eq 0 ]; then
    cat tmp_config.yaml | sed 's/controllers:/controllers:\\n  integration: camel-k/' > camelk_config.yaml
    loop oc replace --force -n ${TARGET_PROJECT} -f camelk_config.yaml
    rm camelk_config.yaml
fi
rm tmp_config.yaml


#
# Pickup some bug fixes by patching the image streams.
#
loop oc patch -n ${TARGET_PROJECT} is syndesis-server --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/redhatdemo/syndesis-server:latest"}]'
loop oc patch -n ${TARGET_PROJECT} is syndesis-meta --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/redhatdemo/syndesis-meta:latest"}]'
loop oc patch -n ${TARGET_PROJECT} is oauth-proxy --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"quay.io/openshift/origin-oauth-proxy:latest"}]'

# TODO remove when https://github.com/syndesisio/syndesis/issues/4960 is fixed
loop oc patch -n ${TARGET_PROJECT} is syndesis-ui --type='json' -p='[{"op": "replace", "path": "/spec/tags/0/from/name", "value":"docker.io/syndesis/syndesis-ui:1.7.1-20190314"}]'
