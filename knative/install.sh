#!/usr/bin/env bash

set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

REPO="$DIR/.repo"
rm -rf "$REPO"
git clone https://github.com/openshift-cloud-functions/knative-operators "$REPO"
pushd $REPO; git checkout c749043 2>/dev/null; popd
"$REPO/etc/scripts/install.sh" -q
