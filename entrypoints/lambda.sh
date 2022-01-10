#!/bin/bash

ARGS=${@:-"/usr/libexec/s2i/run"}

if [ -e /opt/app-root/src/.assembled ]; then
    if [[ $ARGS == "/usr/libexec/s2i/run" ]]; then
        if [ -v AWS_LAMBDA_RUNTIME_API ]; then
            exec "$ARGS"
        else
            exec /opt/aws/aws-lambda-rie "$ARGS"
        fi
    else
        if [ -v AWS_LAMBDA_RUNTIME_API ]; then
            exec anaconda-project run "$ARGS"
        else
            exec /opt/aws/aws-lambda-rie anaconda-project run "$ARGS"
        fi
    fi
else
    exec "$ARGS"
fi
