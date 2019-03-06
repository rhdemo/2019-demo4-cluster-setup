#!/usr/bin/env bash

#set -x

echo 'deploying demo4 front end web app, nodejs server, and python AI gesture service'

[[ -z "${OC_COMMAND}" ]] && { OC_COMMAND=$1; }
[[ -z "${OC_COMMAND}" ]] && { OC_COMMAND='create'; }

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo 'demo4-gesture'

[[ -z "$S3_ENDPOINT" ]] && { echo "S3_ENDPOINT is required" ; exit 1; }
[[ -z "$S3_REGION" ]] && { echo "S3_REGION is required" ; exit 1; }
[[ -z "$S3_BUCKET" ]] && { echo "S3_BUCKET is required" ; exit 1; }
[[ -z "$S3_PREFIX" ]] && { echo "S3_PREFIX is required" ; exit 1; }
[[ -z "$S3_ACCESS_KEY_ID" ]] && { echo "S3_ACCESS_KEY_ID is required" ; exit 1; }
[[ -z "$S3_SECRET_ACCESS_KEY" ]] && { echo "S3_SECRET_ACCESS_KEY is required" ; exit 1; }

SECRET_KEY=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo)

oc process -f ${DIR}/gesture.yml \
  -p S3_ENDPOINT=${S3_ENDPOINT} \
  -p S3_REGION=${S3_REGION} \
  -p S3_BUCKET=${S3_BUCKET} \
  -p S3_PREFIX=${S3_PREFIX} \
  -p S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID} \
  -p S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY} \
  -p SECRET_KEY=${SECRET_KEY} \
  | oc ${OC_COMMAND} -f -

oc process -f ${DIR}/nodejs-server.yml | oc ${OC_COMMAND} -f -

oc process -f ${DIR}/web-game.yml | oc ${OC_COMMAND} -f -
