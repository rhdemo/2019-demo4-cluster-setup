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
# START HACK
#

# This ends up not actually creating the needed stuff, but it does get
# our CRDs applied and the namespace created
install_knative eventing
oc apply -n knative-eventing -f https://raw.githubusercontent.com/openshift-cloud-functions/knative-operators/master/etc/hacks/knative-eventing-0.3.0.yaml

#
# END HACK
#

wait_for_all_pods knative-build
wait_for_all_pods knative-eventing
wait_for_all_pods knative-serving

enable_interaction_with_registry

# skip tag resolving for internal registry
# OpenShift 3 and 4 place the registry in different locations, hence
# the two hostnames here
$CMD -n knative-serving get cm config-controller -oyaml | sed "s/\(^ *registriesSkippingTagResolving.*$\)/\1,docker-registry.default.svc:5000,image-registry.openshift-image-registry.svc:5000/" | oc apply -f -

if $CMD get ns openshift 2>/dev/null; then
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
  $CMD get ns myproject 2>/dev/null || $CMD create namespace myproject
fi

# show all the running pods
$CMD get pods --all-namespaces
