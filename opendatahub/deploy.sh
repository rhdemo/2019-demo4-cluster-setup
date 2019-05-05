#! /bin/bash

# Deploy the Open Data Hub operator into the opendatahub namespace & create a catalog entry for it
# This script will:
#   - create an opendatahub namespace
#   - create an ODH Developer Catalog entry  (THIS NAMEPSACE ONLY)
#   - Deploy the operator
# Once this script is finished you can deploy ODH using the Developer Catalog to create an ODH Custom Resource
# Deleting the ODH Custom Resource will remove JupyterHub, JupyterHub DB and spark operator
# You will have to manually delete the ReplicationController for the deploy Spark master & worker
ODH_NAMESPACE=opendatahub
ODH_DIR=$(dirname "$0")

# Creating the Open Data Hub namespace
oc new-project $ODH_NAMESPACE

# Add the Open Data Hub CRD to the cluster
oc create -f $ODH_DIR/opendatahub_v1alpha1_opendatahub.crd.yaml

# Add the CSV to this namespace to create the ODH developer catalog card
oc create -f $ODH_DIR/opendatahub-operator.v0.2.0.clusterserviceversion.yaml

# Create the operator group to specify which projects get a copy of the ODH CSV
# If you want this to show up in the catalog for all namespaces then delete .spec so that it copies to all templates -- LOOK BUT DON'T TOUCH
# If you want this to show up in the catalog for specific namespaces then add the namespaces to the targetNamespaces list
oc create -f $ODH_DIR/opendatahub-operator.operatorgroup.yaml

# Create the operator service account and assign permissions
oc create -f $ODH_DIR/service_account.yaml -f $ODH_DIR/role.yaml -f $ODH_DIR/role_binding.yaml

# Make the operator service account project admin so JupyterHub can deploy w/o issue
oc adm policy add-role-to-user admin -z opendatahub-operator

# Deploy the operator pod
oc create -f $ODH_DIR/operator.yaml

