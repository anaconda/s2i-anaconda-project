#!/bin/bash

if [ -e /opt/app-root/src/.assembled ]; then
    if [[ $1 == "/usr/libexec/s2i/run" ]]; then
        if [ -v AWS_LAMBDA_RUNTIME_API ]; then
            ## Lambda doesn't seem to like tini at the moment
            exec /usr/libexec/s2i/lambda-bootstrap.sh "$CMD"
        else
            exec tini -g -- "$@"
        fi
    else
        if [ -v AWS_LAMBDA_RUNTIME_API ]; then
            exec /usr/libexec/s2i/lambda-bootstrap.sh "$@"
        else
            exec tini -g -- anaconda-project run "$@"
        fi
    fi
else
    exec tini -g -- "$@"
fi
