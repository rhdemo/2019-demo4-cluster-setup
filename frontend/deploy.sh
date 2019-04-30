#!/usr/bin/env bash

#set -x

echo 'deploying demo4 front end web apps, nodejs servers, and python AI gesture service'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[[ -z "${QUAY_ORG}" ]] && { QUAY_ORG="redhatdemo"; }
[[ -z "${KEY_FILE}" ]] && { KEY_FILE="prod-key.pem"; }
[[ -z "${CERTIFICATE_FILE}" ]] && { CERTIFICATE_FILE="prod-cert.pem"; }
[[ -z "${CA_FILE}" ]] && { CA_FILE="prod-ca.pem"; }

if [[ "${FRONTEND_DEV}" = "true" ]]
then
    echo "Deploying in front end dev mode.  No S3 storage and 1 pod per service."
    KEY=''
    CERTIFICATE=''
    CA_CERTIFICATE=''
    S3_ENDPOINT=''
    S3_REGION=''
    S3_BUCKET=''
    S3_PREFIX=''
    S3_ACCESS_KEY_ID=''
    S3_SECRET_ACCESS_KEY=''
    GESTURE_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    GAME_SERVER_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    GAME_UI_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    ADMIN_SERVER_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    ADMIN_UI_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    DASHBOARD_SERVER_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    DASHBOARD_UI_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    LEADERBOARD_BACKGROUND_PARAMS='-p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    LEADERBOARD_SERVER_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
    LEADERBOARD_UI_PARAMS='-p REPLICAS=1 -p CONTAINER_REQUEST_CPU=100m -p CONTAINER_REQUEST_MEMORY=100Mi -p CONTAINER_LIMIT_CPU=200m -p CONTAINER_LIMIT_MEMORY=500Mi'
else
    KEY=$(cat ${DIR}/../${KEY_FILE})
    CERTIFICATE=$(cat ${DIR}/../${CERTIFICATE_FILE})
    CA_CERTIFICATE=$(cat ${DIR}/../${CA_FILE})
    [[ -z "$S3_ENDPOINT" ]] && { echo "S3_ENDPOINT is missing. No training data will be written" ;}
    [[ -z "$S3_REGION" ]] && { echo "S3_REGION is missing. No training data will be written" ;}
    [[ -z "$S3_BUCKET" ]] && { echo "S3_BUCKET is missing. No training data will be written" ;}
    [[ -z "$S3_PREFIX" ]] && { echo "S3_PREFIX is missing. No training data will be written" ;}
    [[ -z "$S3_ACCESS_KEY_ID" ]] && { echo "S3_ACCESS_KEY_ID is missing. No training data will be written" ;}
    [[ -z "$S3_SECRET_ACCESS_KEY" ]] && { echo "S3_SECRET_ACCESS_KEY is missing. No training data will be written" ;}
    GESTURE_PARAMS='-p REPLICAS=2'
    GAME_SERVER_PARAMS='-p REPLICAS=10'
    GAME_UI_PARAMS='-p REPLICAS=5'
    ADMIN_SERVER_PARAMS='-p REPLICAS=2'
    ADMIN_UI_PARAMS='-p REPLICAS=2'
    DASHBOARD_SERVER_PARAMS='-p REPLICAS=2'
    DASHBOARD_UI_PARAMS='-p REPLICAS=2'
    LEADERBOARD_SERVER_PARAMS='-p REPLICAS=2'
    LEADERBOARD_UI_PARAMS='-p REPLICAS=2'
fi

SECRET_KEY=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)
[[ -z "${SECRET_KEY}" ]] && { SECRET_KEY="iaiRASCmZPsY0S6hj89UlFJ0SI2WZW"; }

oc new-project web-game-demo

oc process -f ${DIR}/demo4-gesture.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-gesture:latest \
  -p S3_ENDPOINT=${S3_ENDPOINT} \
  -p S3_REGION=${S3_REGION} \
  -p S3_BUCKET=${S3_BUCKET} \
  -p S3_PREFIX=${S3_PREFIX} \
  -p S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID} \
  -p S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY} \
  -p SECRET_KEY=${SECRET_KEY} \
  ${GESTURE_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-admin-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-admin-server:latest \
  ${ADMIN_SERVER_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-admin-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-admin-nginx:latest \
  ${ADMIN_UI_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-dashboard-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-dashboard-server:latest \
  ${DASHBOARD_SERVER_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-dashboard-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-dashboard-nginx:latest \
  ${DASHBOARD_UI_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-web-game-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-web-game-server:latest \
  ${GAME_SERVER_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-web-game-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-web-game-nginx:latest \
  -p KEY="${KEY}" \
  -p CERTIFICATE="${CERTIFICATE}" \
  -p CA_CERTIFICATE="${CA_CERTIFICATE}" \
  ${GAME_UI_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-leaderboard-background.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-leaderboard-background:latest \
  ${LEADERBOARD_BACKGROUND_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-leaderboard-server.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-leaderboard-server:latest \
  ${LEADERBOARD_SERVER_PARAMS} \
  | oc create -f -

oc process -f ${DIR}/demo4-leaderboard-ui.yml \
  -p IMAGE_REPOSITORY=quay.io/${QUAY_ORG}/demo4-leaderboard-nginx:latest \
  ${LEADERBOARD_UI_PARAMS} \
  | oc create -f -