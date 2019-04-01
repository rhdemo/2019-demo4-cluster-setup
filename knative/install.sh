#!/usr/bin/env bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

REPO="$DIR/.repo"
rm -rf "$REPO"
git clone https://github.com/openshift-cloud-functions/knative-operators "$REPO"
pushd $REPO; git checkout openshift-v0.3.0 2>/dev/null; popd

# This is a direct copy of $REPO/etc/scripts/install.sh except for a
# change to not install Knative Eventing since it doesn't work with
# the latest OLM. This does, however, install Knative Eventing Sources
# via the line that applies that hack/knative-evennting-0.3.0.yaml.

source "$REPO/etc/scripts/installation-functions.sh"
# installation-functions.sh wasn't designed to run w/ set -e
set +e

install_catalogsources
install_istio
install_knative build
install_knative serving

#
# START SERVING AND ISTIO MESH HACK
#

# The image below is created from
# https://github.com/bbrowning/serving/tree/demo2019. Clone
# the repo, checkout the demo2019 branch, then run:
#
# KO_DOCKER_REPO=docker.io/bbrowning ko resolve -f contrib/controller.yaml
#
# and copy the image value here
SERVING_DEMO_CONTROLLER_IMAGE="controller-43f0364ab2f6dab17267e80a1f6a4adc@sha256:881ff60149619af91f70dcd4d18d55e4810c4450d4219ba82def5411fc9a2e59"
oc patch deployment controller -n knative-serving -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\": \"controller\", \"image\":\"$SERVING_DEMO_CONTROLLER_IMAGE\"}]}}}}"

#
# END SERVING AND ISTIO MESH HACK
#

#
# START EVENTING AND OLM HACK
#

# This ends up not actually creating the needed stuff, but it does get
# our CRDs applied and the namespace created
install_knative eventing
oc apply -n knative-eventing -f https://raw.githubusercontent.com/openshift-cloud-functions/knative-operators/master/etc/hacks/knative-eventing-0.3.0.yaml

#
# END EVENTING AND OLM HACK
#

wait_for_all_pods knative-build
wait_for_all_pods knative-eventing
wait_for_all_pods knative-serving

enable_interaction_with_registry

# skip tag resolving for internal registry
# OpenShift 3 and 4 place the registry in different locations, hence
# the two hostnames here
oc -n knative-serving get cm config-controller -oyaml | sed "s/\(^ *registriesSkippingTagResolving.*$\)/\1,docker-registry.default.svc:5000,image-registry.openshift-image-registry.svc:5000/" | oc apply -f -

if oc get ns openshift 2>/dev/null; then
  # Add Golang imagestreams to be able to build go based images
  oc import-image -n openshift golang --from=centos/go-toolset-7-centos7 --confirm
  oc import-image -n openshift golang:1.11 --from=centos/go-toolset-7-centos7 --confirm

  if ! oc project myproject 2>/dev/null; then
    oc new-project myproject
  fi
  # these perms are required by istio
  oc adm policy add-scc-to-user privileged -z default
  oc adm policy add-scc-to-user anyuid -z default
else
  oc get ns myproject 2>/dev/null || oc create namespace myproject
fi

# Install Knative KafkaSource
#
# This is our branch that just stages some not-yet-merged fixes to the
# upstream Knative KafkaSource.
oc create ns knative-sources
set -e
oc apply -f https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/200-serviceaccount.yaml
oc apply -f https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/201-clusterrole.yaml
oc apply -f https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/202-clusterrolebinding.yaml
oc apply -f https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/300-kafkasource.yaml
oc apply -f https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/400-controller-service.yaml

# Two images below created from
# https://github.com/bbrowning/eventing-sources/tree/kafka-demo. Clone
# the repo, checkout the kafka-demo branch, then run:
#
# KO_DOCKER_REPO=docker.io/bbrowning ko resolve -f contrib/kafka/config/500-controller.yaml
#
# and copy the image values here
KAFKA_DEMO_CONTROLLER_IMAGE="index.docker.io/bbrowning/controller-b9dd81bd360d16d6b7c6cd69487d72a5@sha256:b76e200fe2ac7aa74675201b1f7c099ab25326cf2fd654c835cfa989e42aa0da"
KAFKA_DEMO_RA_IMAGE="index.docker.io/bbrowning/receive_adapter-a3ffe8766802b0f13e2a5cc64eceba7c@sha256:5f2a55526932044c6eeb8b847528bbd92168e04a85f250c32e062f935203ac39"
curl -L https://raw.githubusercontent.com/bbrowning/eventing-sources/kafka-demo/contrib/kafka/config/500-controller.yaml | sed -e "s|github.com/knative/eventing-sources/contrib/kafka/cmd/controller|${KAFKA_DEMO_CONTROLLER_IMAGE}|" -e "s|github.com/knative/eventing-sources/contrib/kafka/cmd/receive_adapter|${KAFKA_DEMO_RA_IMAGE}|" | oc apply -f -

set +e

wait_for_all_pods knative-sources


# show all the running pods
oc get pods --all-namespaces
