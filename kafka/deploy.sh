#!/bin/bash

echo "STRIMZI_NAMESPACE=" $STRIMZI_NAMESPACE
echo "STRIMZI_CLUSTER=" $STRIMZI_CLUSTER

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# download Strimzi release
wget https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.11.1/strimzi-0.11.1.tar.gz
mkdir $DIR/strimzi
tar xzf strimzi-0.11.1.tar.gz -C $DIR/strimzi --strip 1
rm strimzi-0.11.1.tar.gz

# cluster deployment
$DIR/01-deploy-strimzi.sh
$DIR/02-deploy-kafka.sh
$DIR/03-deploy-topics.sh
$DIR/04-deploy-console-server.sh
$DIR/05-deploy-console.sh
$DIR/06-deploy-monitoring.sh

rm -rf $DIR/strimzi