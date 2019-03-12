#!/usr/bin/env bash

set -ex


TARGET_PROJECT=camel-k
oc new-project ${TARGET_PROJECT} | true

GITHUB_CONTENT=https://raw.githubusercontent.com/apache/camel-k/master

#
# Cleanup
#
oc delete --force it --all
oc delete --force ictx --all
oc delete --force cc --all

#
# Install the CRD.
#
oc replace --force -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration-platform.yaml
oc replace --force -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration-context.yaml
oc replace --force -n openshift -f ${GITHUB_CONTENT}/deploy/crd-integration.yaml
oc replace --force -n openshift -f ${GITHUB_CONTENT}/deploy/crd-camel-catalog.yaml
oc replace --force -n openshift -f ${GITHUB_CONTENT}/deploy/user-cluster-role.yaml

#
# Install the Camel K Operator
#
oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-service-account.yaml
oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-openshift.yaml
oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-binding.yaml
oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-knative.yaml
oc replace --force -n ${TARGET_PROJECT} -f ${GITHUB_CONTENT}/deploy/operator-role-binding-knative.yaml

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
          imagePullPolicy: IfNotPresent
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
    - none
EOF
