#!/bin/sh

RESOURCE_DIR=$(dirname "$0")


oc new-project machine-history

oc create -f $RESOURCE_DIR/template.yaml
oc new-app machine-history


