#!/usr/bin/env bash

set -o errexit

path=${1?path is required}
couch_db=${COUCH_DB:-$COUCH_LOCAL}

function couch() {
    path=$1
    curl -Hcontent-type:application/json \
        -Haccept:application/json \
        "$couch_db$path"
}


resp=$(couch "$path?revs=true&open_revs=all")
rev=$(echo "$resp" | jq -r .[].ok._rev)
# couch $path?rev=$rev

