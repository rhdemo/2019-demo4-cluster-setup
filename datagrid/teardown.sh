#!/bin/bash
oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,serviceaccounts --selector=template=datagrid-service
oc delete configmap datagrid-config
oc get pvc -o name | xargs -r -n1 oc delete

