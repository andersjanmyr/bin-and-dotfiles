#!/bin/bash

servers=server_id=${SERVER_ID:-'phpweb-prod6'}
tmp_dir=~/tmp

couch() {
    curl --fail --silent -Hcontent-type:application/json $@
}


refresh_company() {
    url=$1
    id=$2
    prefix="$tmp_dir/$id"
    couch "$url/smrt_companies_${id}/_all_docs?include_docs=true" | jq > "$prefix.json"
    cat "$prefix.json" | jq -r .rows[].doc._id |sed 's/business_//' > "$prefix.txt"
}

refresh_company $COUCH_PROD phpweb-prod3
refresh_company $COUCH_PROD phpweb-prod5
refresh_company $COUCH_PROD phpweb-prod6
refresh_company $COUCH_PROD apac
refresh_company $COUCH_PROD emea
refresh_company $COUCH_QA smrtqa
