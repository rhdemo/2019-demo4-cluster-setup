#!/usr/bin/env bash

set -ex
dir=$(dirname $0)
source $dir/common.sh

TARGET_PROJECT=${1:-camel-k}
# TODO before the summit, use a tag, not master
oc new-project ${TARGET_PROJECT} | true

#
# Add permissions for Istio
#
loop oc adm policy add-scc-to-user privileged -n $TARGET_PROJECT -z default
loop oc adm policy add-scc-to-user anyuid -n $TARGET_PROJECT -z default


GITHUB_CONTENT=https://raw.githubusercontent.com/apache/camel-k/master

#
# Cleanup
#
oc delete --force it --all | true
oc delete --force ictx --all | true
oc delete --force cc --all | true

#
# Install the CRD.
#
loop oc apply -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration-platform.yaml
loop oc apply -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration-context.yaml
loop oc apply -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration.yaml
loop oc apply -n openshift -f ${GITHUB_CONTENT}/deploy/crd-camel-catalog.yaml
loop oc apply -n openshift -f ${GITHUB_CONTENT}/deploy/user-cluster-role.yaml

#
# Install the Camel K Operator
#
loop oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-service-account.yaml
loop oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-openshift.yaml
loop oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-binding.yaml
loop oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-knative.yaml
loop oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-binding-knative.yaml

#
# Install custom bits
#
oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: camel-k-operator
  labels:
    app: "camel-k"
    camel.apache.org/component: operator
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      name: camel-k-operator
  template:
    metadata:
      labels:
        name: camel-k-operator
        camel.apache.org/component: operator
    spec:
      serviceAccountName: camel-k-operator
      containers:
        - name: camel-k-operator
          image: quay.io/redhatdemo/camel-k:latest
          command:
          - camel-k
          imagePullPolicy: Always
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: OPERATOR_NAME
              value: "camel-k"
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
EOF


oc replace --force -n ${TARGET_PROJECT} -f - <<EOF
apiVersion: camel.apache.org/v1alpha1
kind: IntegrationPlatform
metadata:
  name: camel-k
  labels:
    app: "camel-k"
spec:
  build:
    repositories:
    - https://repository.apache.org/content/repositories/snapshots@id=apache.snapshots@snapshots@noreleases
    - https://oss.sonatype.org/content/repositories/snapshots/@id=sonatype.snapshots@snapshots@noreleases
    - https://maven.repository.redhat.com/ga@id=redhat.ga
    - https://origin-repository.jboss.org/nexus/content/groups/ea@id=redhat.ea
  cluster: OpenShift
  profile: Knative
  resources:
    contexts:
    - knative
  traits:
    knative-service:
      configuration:
        autoscaling-metric: concurrency
        autoscaling-target: "1"
        max-scale: "100"
        min-scale: "0"
EOF

oc apply -n ${TARGET_PROJECT} -f - <<EOF
apiVersion: camel.apache.org/v1alpha1
kind: Integration
metadata:
  creationTimestamp: null
  name: load
  namespace: syndesis
spec:
  replicas: 0
  sources:
  - content: |-
      event = '''{
          "sensorId": "360a3255-7b14-45b8-9624-8ee396a716c8",
          "machineId": 3,
          "vibrationClass": 1,
          "confidencePercentage": 80
      }'''

      from("timer:clock?period=100")
          .log('tick')
          .setBody().constant(event)
          .to("seda:queue?waitForTaskToComplete=Never")

      from("seda:queue?concurrentConsumers=20")
          .log('Sending: ${body}')
          .to("knative:endpoint/i-sensor-to-damagex")
    name: load.groovy
EOF
