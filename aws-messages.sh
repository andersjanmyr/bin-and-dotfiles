#/bin/bash

set -o errexit

env=${1?'env is required'}
queue=${2?'queue is required'}
count=${3:-1}

aws_profile="cdk-$1"

aws --profile $aws_profile sqs receive-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/$queue \
    --max-number-of-messages $count \
    | jq -c '.Messages[].Body | fromjson'
