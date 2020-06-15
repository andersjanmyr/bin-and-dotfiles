#!/bin/bash
conf_name=$1
if [ -n "$conf_name" ]; then
  profiles=$(cat ~/.aws/config |grep '^\[profile' |tr -d '[]' | awk '{print $2}')
  for profile in $profiles; do
    if [ "$profile" == "$conf_name" ]; then
      export AWS_PROFILE=$profile
    fi;
  done;
fi
echo "AWS Profile: $AWS_PROFILE"
