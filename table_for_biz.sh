#!/bin/bash

pattern=${1?'biz pattern is required'}
table=${2:-'.*'}
env=${env:-prod}

biz=$(env=$env biz.sh $pattern)

if [[ $env == 'qa' ]]; then
    grep "_${biz}_${table}" ~/tmp/couch_all_dbs_qa.txt
else
    grep "_${biz}_${table}" ~/tmp/couch_all_dbs_prod.txt
fi

