#!/usr/bin/env bash

set -o errexit

file=${1?'file is required'}
name=${2:-'master'}

function to_db() {
    awk -v name=$name 'BEGIN { FS=":" } { suffix= ($2!="null" ? ("_" $2) : ""); print "smrt_b_" $1 "_" name suffix }'
}

for row in $(cat $file | jq -rc '.rows[].doc | "\(.subdomain):\(.database_suffix)"' | grep -v '^null'); do
    db=$(echo $row | to_db)
    echo $db
done

