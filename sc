#!/bin/bash

env=${1:-''}
if [[ $1 == '' ]]; then
    env=$(echo -e "apac\nemea\nprod3\nprod5\nprod6\nqa3" | fzf)
fi
if [[ $env != '' ]]; then
    smrt -e $env connect sysop /bin/bash
fi
