#!/bin/bash

if [ -e /opt/app-root/src/.assembled ]; then
    if [[ $1 == "/usr/libexec/s2i/run" ]]; then
        exec tini -g -- "$@"
    else
        exec tini -g -- anaconda-project run "$@"
    fi
else
    exec tini -g -- "$@"
fi
