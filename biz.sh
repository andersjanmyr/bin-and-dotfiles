#!/bin/bash

pattern=${1?'pattern is required'}
number='^[0-9]+$'
if [[ $pattern =~ $number ]]; then
    pattern="\"bid\":$pattern,";
fi
query=${2:-'.subdomain'}
env=${env:-prod}

if [[ $env == 'qa' ]]; then
    cat ~/tmp/smrtqa.json | jq -c .rows[].doc | grep "$pattern" | jq -r "$query"
else
    result=$(cat ~/tmp/phpweb-prod{3,5,6}.json | jq -c .rows[].doc | grep "$pattern" | jq -r ".")
    subdomain=$(echo "$result" | jq -r ".subdomain")
    echo "$result" | jq -r "$query"
    grep -l "$subdomain" ~/tmp/phpweb-prod{3,5,6}.txt >&2
fi

