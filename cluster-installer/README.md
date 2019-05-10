*HOWTO get an OCP4 cluster running to run this demo*

These instructions are based on https://cloud.redhat.com/openshift/install.

# Pre-requisites

## AWS credentials

To setup an OCP4 cluster that is enabled to run this demo, an AWS account with 'admin' privileges is required. It will be necessary to ensure that the `~/.aws` directory contains the correct `aws_access_key_id` and `aws_secret_access_key` for this account.

## Setup environment vars

If not done so already, ensure that the following section in the `.env` file is added and populated. See the `.env.example` file as a template.

```
# OCP4 cluster installation
CLUSTER_NAME=ChangeMe # E.g. demo2019
CLUSTER_CONFIG_HOME=ChangeMe # E.g. /Users/someuser/tmp/repos/2019-demo4-cluster-setup/demo2019-config
MASTER_EC2_TYPE=ChangeMe # E.g. c5.xlarge
WORKER_EC2_TYPE=ChangeMe # E.g. c5.xlarge
AWS_REGION=ChangeMe # E.g. ap-southeast-2
VERSION=ChangeMe # E.g. 0.16.1
```

A note about instance sizes: This demo does require some significant EC2 horsepower. It is recommended to use at least `c5.xlarge` instances.

## Setup a working directory

A config file needs to be written for this to work. After creating a working directory, update the `CLUSTER_CONFIG_HOME` variable in the `.env` file.

## Download installer

Navigate to https://cloud.redhat.com/openshift/install and download the Installer for the appropriate architecture from:

https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/

Rename the downloaded executable to `./openshift-installer`, and copy to CLUSTER_CONFIG_HOME. Ensure execute bits are set:

`chmod a+x ./openshift-installer`

Also, download the "Pull Secret" and record for later.

## Generate an install-config.yaml

Run the following command and answer the prompts:

`./openshift-installer create install-config`

Modify the `install-config.yaml` file to include the following sections to allow for customisations of AWS infrastructure as per this documentation:

```
compute:
- name: worker
  platform:
    aws:
      rootVolume:
        size: 500
        type: gp2
      type: m5.2xlarge
      zones:
  replicas: 6
controlPlane:
  name: master
  platform:
    aws:
      type: c5.2xlarge
  replicas: 3
```

Don't forget to set the appropriate EC2 instance size (`type`) and the EBS volume size (`rootVolume.size` in Gb).

Note: If you want to use it again, back-up the `install-config.yaml` file as it does get deleted during the cluster creation process.

## Create a cluster

Start the provisioning process by running:

`./openshift-installer create cluster`

When the cluster is provisioned, cluster credentials will be displayed. Use these to login to the cluster and then setup whatever identity provider is appropriate.

Note: This process generates a metadata.json file in the same directory which can be used to destroy the cluster. 

# Cleaning-up

To destroy the cluster run:

`./openshift-installer destroy cluster`

This does require that the `metadata.json` file (created during the "create cluster" process) exists in the same directory as the Installer.