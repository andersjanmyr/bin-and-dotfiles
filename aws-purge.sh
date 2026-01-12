#/bin/bash

set -o errexit

queue=${1?'queue is required'}

calc_env() {
    case "$1" in
        qa_smrtqa*)
            echo "qa3"
            ;;
        production_phpweb-*)
            local tmp=${1#production_phpweb-}
            echo ${tmp%_aaa*}
            ;;
        production_*)
            local tmp=${1#production_}
            echo ${tmp%_aaa*}
            ;;
        *)
            echo "Invalid queue name: $1"
            exit 1
            ;;
    esac
}

env=$(calc_env $queue)
aws_profile="cdk-$env"

aws --profile $aws_profile sqs purge-queue \
    --queue-url https://sqs.us-east-1.amazonaws.com/$queue
