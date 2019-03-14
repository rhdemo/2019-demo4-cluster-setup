#!/usr/bin/env bash

# Waits until the command succeeds.
# Example: loop oc get cm syndesis-server-config -n myproject -o yaml
#
loop() {
    while : ; do
        if "$@" ; then
            break
        fi
        sleep 1
    done
}

# Waits until the command output matches the first argument.
# Example: wait_for "Starting" oc get syndesis default -n myproject -o=jsonpath="{.status.phase}"
# 
wait_for() {
  local value=$1
  shift
  while : ; do
    if [[ $("$@") = "$value" ]]; then
        break
    fi
    sleep 1
  done
}
