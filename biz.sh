#!/bin/bash

pattern=${1?'pattern is required'}
number='^[0-9]+$'
query=${2}
if [[ $pattern =~ $number ]]; then
    pattern="\"bid\":$pattern,";
    if [[ -z $query ]]; then
        query='.subdomain'
    fi
fi
if [[ -z $query ]]; then
    query='.bid'
fi
env=${env:-prod}

prod_envs=$(ls ~/tmp/phpweb-prod{3,5,6}.json ~/tmp/apac.json ~/tmp/emea.json)

if [[ $env == 'qa' ]]; then
    cat ~/tmp/smrtqa.json | jq -c .rows[].doc | grep "$pattern" | jq -r "$query"
else
    result=$(cat $prod_envs | jq -c .rows[].doc | grep "$pattern" | jq -r ".")
    subdomain=$(echo "$result" | jq -r ".subdomain")
    echo "$result" | jq -r "$query"
    grep -l "$subdomain" $prod_envs >&2
fi

