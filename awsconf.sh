#!/bin/bash
conf_name=$1
if [ -n "$conf_name" ]; then
  avail_profiles=$((unset AWS_DEFAULT_PROFILE && COMMAND_LINE="configure --profile" aws_completer) | grep -v _path)
  for profile in $avail_profiles; do
    if [ "$profile" == "$conf_name" ]; then
      export AWS_DEFAULT_PROFILE=$profile
      export AWS_PROFILE=$profile
    fi;
  done;
fi
echo "AWS Profile: $AWS_DEFAULT_PROFILE"
