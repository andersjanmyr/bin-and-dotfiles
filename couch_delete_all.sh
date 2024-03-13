#!/usr/bin/env bash

set -o errexit

couch_url=${COUCH_URL:-$COUCH_LOCAL}
db=${1?'db is required'}
tmp_dir='./tmp'
tmp_file="$tmp_dir/tmp.racklogs.json"
script_dir=$(dirname -- ${BASH_SOURCE[0]})

function couch() {
    path=$1
    shift
    curl --silent -Hcontent-type:application/json \
        -Haccept:application/json \
        "$couch_url$path" "$@"
}

mkdir -p $tmp_dir
couch "/$db/_all_docs?start_key=\"RackLog\"&end_key=\"RackLog_z\"" > $tmp_file
$script_dir/couch_exp_to_del.sh $tmp_file $tmp_dir
tree $tmp_dir
read
for f in $tmp_dir/??.json; do
    couch /$db/_bulk_docs -XPOST -d @$f
done
rm -rf $tmp_dir
