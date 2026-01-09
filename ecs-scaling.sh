#!/bin/bash

cloud=${1:-prod6}
profile="cdk-$cloud"

aws --profile $profile application-autoscaling describe-scalable-targets --service-namespace ecs \
    | jq -c '.ScalableTargets[] | { ResourceId, MinCapacity, MaxCapacity }' \
    | sort
