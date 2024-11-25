#!/bin/bash

biz=${1?'biz is required'}
table=${2:-'.*'}
env=${env:-prod}

if [[ $env == 'qa' ]]; then
    grep "_${biz}_${table}" ~/tmp/couch_all_dbs_qa.txt
else
    grep "_${biz}_${table}" ~/tmp/couch_all_dbs_prod.txt
fi

