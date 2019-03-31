#!/usr/bin/env bash

#set -x

echo 'deploying demo4 front end web apps, nodejs servers, and python AI gesture service'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[[ -z "${QUAY_ORG}" ]] && { QUAY_ORG="redhatdemo"; }

if [[ "${FRONTEND_DEV}" = "true" ]]
then
    echo "Deploying in front end dev mode.  No S3 storage and 1 pod per service."
    GESTURE_REPLICAS=1
    GAME_UI_REPLICAS=1
    GAME_SERVER_REPLICAS=1
    ADMIN_UI_REPLICAS=1
    ADMIN_SERVER_REPLICAS=1
    DASHBOARD_UI_REPLICAS=1
    DASHBOARD_SERVER_REPLICAS=1
    S3_ENDPOINT=''
    S3_REGION=''
    S3_BUCKET=''
    S3_PREFIX=''
    S3_ACCESS_KEY_ID=''
    S3_SECRET_ACCESS_KEY=''
else
    GESTURE_REPLICAS=5
    GAME_UI_REPLICAS=5
    GAME_SERVER_REPLICAS=10
    ADMIN_UI_REPLICAS=2
    ADMIN_SERVER_REPLICAS=2
    DASHBOARD_UI_REPLICAS=2
    DASHBOARD_SERVER_REPLICAS=2
    [[ -z "$S3_ENDPOINT" ]] && { echo "S3_ENDPOINT is missing. No training data will be written" ;}
    [[ -z "$S3_REGION" ]] && { echo "S3_REGION is missing. No training data will be written" ;}
    [[ -z "$S3_BUCKET" ]] && { echo "S3_BUCKET is missing. No training data will be written" ;}
    [[ -z "$S3_PREFIX" ]] && { echo "S3_PREFIX is missing. No training data will be written" ;}
    [[ -z "$S3_ACCESS_KEY_ID" ]] && { echo "S3_ACCESS_KEY_ID is missing. No training data will be written" ;}
    [[ -z "$S3_SECRET_ACCESS_KEY" ]] && { echo "S3_SECRET_ACCESS_KEY is missing. No training data will be written" ;}
fi

SECRET_KEY=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)
[[ -z "${SECRET_KEY}" ]] && { SECRET_KEY="iaiRASCmZPsY0S6hj89UlFJ0SI2WZW"; }

oc new-project web-game-demo

echo 'demo4-gesture'
oc process -f ${DIR}/demo4-gesture.yml \
  -p REPLICAS=${GESTURE_REPLICAS} \
  -p S3_ENDPOINT=${S3_ENDPOINT} \
  -p S3_REGION=${S3_REGION} \
  -p S3_BUCKET=${S3_BUCKET} \
  -p S3_PREFIX=${S3_PREFIX} \
  -p S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID} \
  -p S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY} \
  -p SECRET_KEY=${SECRET_KEY} \
  | oc create -f -

oc process -f ${DIR}/demo4-admin-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-admin-server:latest \
  -p REPLICAS=${ADMIN_SERVER_REPLICAS} \
  | oc create -f -

oc process -f ${DIR}/demo4-admin-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-admin-nginx:latest \
  -p REPLICAS=${ADMIN_UI_REPLICAS} \
  | oc create -f -

oc process -f ${DIR}/demo4-dashboard-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-dashboard-server:latest \
  -p REPLICAS=${DASHBOARD_SERVER_REPLICAS} \
  | oc create -f -

oc process -f ${DIR}/demo4-dashboard-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-dashboard-nginx:latest \
  -p REPLICAS=${DASHBOARD_UI_REPLICAS} \
  | oc create -f -

oc process -f ${DIR}/demo4-web-game-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-web-game-server:latest \
  -p REPLICAS=${GAME_SERVER_REPLICAS} \
  | oc create -f -

oc process -f ${DIR}/demo4-web-game-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-web-game-nginx:latest \
  -p REPLICAS=${GAME_UI_REPLICAS} \
  | oc create -f -
