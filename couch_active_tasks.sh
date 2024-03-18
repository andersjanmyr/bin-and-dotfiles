#!/bin/bash

filter=${1:-""}

couchp () {
    curl --silent -H 'Content-Type:application/json' ${COUCH_PROD}$1 $2 $3 $4 $5 $6 $7
}

tasks=$(couchp /_active_tasks | jq -c '.[]')

echo "$tasks" \
    | grep "replication" \
    | grep "$filter" \
    | jq -r '"\(.node) \(.process_status) \(.docs_read)/\(.docs_written)/\(.doc_write_failures) \(.changes_pending) \(.doc_id) \(.type)"' \
    | sed 's/couchdb@//' | sed 's/\.smrt\.internal//' | sed 's#shards/00000000-ffffffff/##' \
    | column -t
echo "$tasks" \
    | grep -v "replication" \
    | grep "$filter" \
    | jq -r '"\(.node) \(.process_status) \(.changes_done)/\(.total_changes) \(.changes_done*100/.total_changes|round) \(.database) \(.type) \(.design_document)"' \
    | sed 's/couchdb@//' | sed 's/\.smrt\.internal//' | sed 's#shards/00000000-ffffffff/##' \
    | column -t
