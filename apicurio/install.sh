#!/bin/sh
DB_USER=apicuriodb
DB_PASS=adsfadsjkl923ksdaDSFa
KC_USER=admin
KC_PASS=quarkus
RESOURCE_DIR=$(dirname "$0")
oc new-project apicurio
oc create -f $RESOURCE_DIR/apicurio-template.yaml
oc new-app apicurio-studio-standalone -p KC_USER=$KC_USER -p KC_PASS=$KC_PASS