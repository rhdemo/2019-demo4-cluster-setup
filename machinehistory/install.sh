#!/bin/sh

RESOURCE_DIR=$(dirname "$0")


oc new-project machine-history


#setup the postgres instances
oc new-app docker.io/swd847/postgres-dev --name=machine-history-postgres-dev
oc set env dc/machine-history-postgres-dev POSTGRES_USER=machine_history_user POSTGRES_PASSWORD=DSAf3DSdfhjkl39s9 POSTGRES_DB=machine_history_dev
oc set volume dc/machine-history-postgres-dev --add --name=machine-history-postgres-dev-volume-1 -m /var/lib/postgresql --overwrite



oc new-build https://github.com/stuartwdouglas/quarkus-images.git --context-dir=centos-quarkus-jvm-s2i --name quarkus-jvm-s2i
oc logs -f bc/quarkus-jvm-s2i
oc secrets new-sshauth machine-history-deployment-key --ssh-privatekey=id_rsa
oc secrets link builder machine-history-deployment-key

oc new-app quarkus-jvm-s2i~git@github.com:rhdemo/2019-demo4-machine-history.git#final-state --context-dir=machine-history --name=machine-history-uberjar
oc set env dc/machine-history-uberjar QUARKUS_DATASOURCE_URL=jdbc:postgresql://machine-history-postgres-dev:5432/machine_history_dev


oc logs -f bc/machine-history-uberjar
oc set build-secret --source bc/machine-history-uberjar machine-history-deployment-key
oc start-build machine-history-uberjar
oc logs -f bc/machine-history-uberjar
oc expose svc/machine-history-uberjar


