#!/usr/bin/env bash

loop() {
    while true ; do
        if "$@" ; then
            break
        fi
        sleep 1
    done
}