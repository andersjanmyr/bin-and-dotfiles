#!/bin/bash

tmp_dir=~/tmp

couch() {
    curl --fail --silent -Hcontent-type:application/json $@
}


refresh_dbs() {
    url=$1
    env=$2
    prefix="$tmp_dir/couch_all_dbs_$env"
    couch "$url/_all_dbs" | jq > "$prefix.json"
    cat "$prefix.json" | jq -r .[] > "$prefix.txt"
    cat "$prefix.txt" | grep -e '_master_' -e '_master$' >"${prefix}_masters.txt"
}

refresh_dbs $COUCH_PROD prod
refresh_dbs $COUCH_QA qa
