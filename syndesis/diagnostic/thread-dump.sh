#!/usr/bin/env bash

for POD in $(oc get pods | grep damage-game- | grep "Running" | awk '{ print $1 }')
do 
    oc exec -c user-container ${POD} -- jstack -l 1 >> ${POD}.txt
done

