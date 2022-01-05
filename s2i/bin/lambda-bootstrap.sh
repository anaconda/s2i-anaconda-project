#!/bin/bash

# Adapted from https://github.com/gkrizek/bash-lambda-layer/blob/master/bootstrap

set -uo pipefail

COMMAND=${@:-default}

# Constants
RUNTIME_PATH="2018-06-01/runtime"
mkdir -p /tmp/.aws
touch /tmp/.aws/config
export HOME="/tmp"
export AWS_CONFIG_FILE="/tmp/.aws/config"

# Send initialization error to Lambda API
sendInitError () {
  ERROR_MESSAGE=$1
  ERROR_TYPE=$2
  ERROR="{\"errorMessage\": \"$ERROR_MESSAGE\", \"errorType\": \"$ERROR_TYPE\"}"
  curl -sS -X POST -d "$ERROR" "http://${AWS_LAMBDA_RUNTIME_API}/${RUNTIME_PATH}/init/error" > /dev/null
}

# Send runtime error to Lambda API
sendRuntimeError () {
  REQUEST_ID=$1
  ERROR_MESSAGE=$2
  ERROR_TYPE=$3
  STACK_TRACE=$4
  ERROR="{\"errorMessage\": \"$ERROR_MESSAGE\", \"errorType\": \"$ERROR_TYPE\", \"stackTrace\": \"$STACK_TRACE\"}"
  curl -sS -X POST -d "$ERROR" "http://${AWS_LAMBDA_RUNTIME_API}/${RUNTIME_PATH}/invocation/${REQUEST_ID}/error" > /dev/null
}

# Send successful response to Lambda API
sendResponse () {
  REQUEST_ID=$1
  REQUEST_RESPONSE_FILE=$2
  cat $REQUEST_RESPONSE_FILE | curl -sS -X POST -d @- "http://${AWS_LAMBDA_RUNTIME_API}/${RUNTIME_PATH}/invocation/${REQUEST_ID}/response" > /dev/null
}

# # Make sure handler function exists
# type "$(echo $_HANDLER | cut -d. -f2)" > /dev/null 2>&1
# if [[ ! $? -eq "0" ]]; then
#   sendInitError "Failed to load handler '$(echo $_HANDLER | cut -d. -f2)' from module '$(echo $_HANDLER | cut -d. -f1)'. Function '$(echo $_HANDLER | cut -d. -f2)' does not exist." "InvalidHandlerException"
#   exit 1
# fi

# Processing
while true
do
  HEADERS="/tmp/headers-$(date +'%s')"
  RESPONSE_FILE="/tmp/response-$(date +'%s')"
  touch $HEADERS
  touch $RESPONSE_FILE
  EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/${RUNTIME_PATH}/invocation/next")
  REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
  # Export some additional context
  export AWS_LAMBDA_REQUEST_ID=$REQUEST_ID
  export AWS_LAMBDA_DEADLINE_MS=$(grep -Fi Lambda-Runtime-Deadline-Ms "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
  export AWS_LAMBDA_FUNCTION_ARN=$(grep -Fi Lambda-Runtime-Invoked-Function-Arn "$HEADERS" | cut -d" " -f2)
  export AWS_LAMBDA_TRACE_ID=$(grep -Fi Lambda-Runtime-Trace-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
  # Execute the command
  anaconda-project run $COMMAND "$EVENT_DATA" &> $RESPONSE_FILE
  EXIT_CODE=$?
  # Respond to Lambda API
  if [[ $EXIT_CODE -eq "0" ]]; then
    sendResponse "$REQUEST_ID" "$RESPONSE_FILE"
  else
    # Log error to stdout as well
    cat $RESPONSE_FILE
    sendRuntimeError "$REQUEST_ID" "Exited with code $EXIT_CODE" "RuntimeErrorException" "$(cat $RESPONSE_FILE)"
  fi
  # Clean up
  rm -f -- "$HEADERS"
  rm -f -- "$RESPONSE_FILE"
  unset HEADERS
  unset RESPONSE
done