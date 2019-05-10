#!/usr/bin/env bash

set -o errexit
set -o pipefail

######################################################################
#
# Wrapper script to create an OpenShift 4 cluster in the provided AWS
# account that is setup for running the 2019 Summit keynote demo.
#
######################################################################

source .env

################################
# FUNCTIONS
################################

function debug {
    # echo out all the command line args
    echo "${CLUSTER_NAME}"
    echo "${MASTER_EC2_TYPE}"
    echo "${WORKER_EC2_TYPE}"
    echo "${AWS_REGION}"
    echo "${CLUSTER_CONFIG_HOME}"
}

function make_config_dir {
    # create temporary directory to store cluster configuration
    mkdir -p "${CLUSTER_CONFIG_HOME}"
}

function download_installer {
    if [ -L ${CLUSTER_CONFIG_HOME}/openshift-installer ] ; then
        echo "Installer already downloaded (skip)."
    else
        # get path for installer binary
        local KERNEL=$(uname -s)
        if [ $KERNEL = "Darwin" ]; then
            INSTALLER_URL=https://github.com/openshift/installer/releases/download/v$VERSION/openshift-install-darwin-amd64
        elif [ $KERNEL = "Linux" ]; then
            INSTALLER_URL=https://github.com/openshift/installer/releases/download/v$VERSION/openshift-install-linux-amd64
        else
            echo "Unsupported OS"
        fi

        # download
        wget $INSTALLER_URL -O ${CLUSTER_CONFIG_HOME}/openshift-installer
        chmod a+x ${CLUSTER_CONFIG_HOME}/openshift-installer
    fi
}


################################
# MAIN
################################
debug; #uncomment to display command line args
make_config_dir;
download_installer;
