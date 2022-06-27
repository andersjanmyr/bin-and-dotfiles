#!/bin/bash -x

set -o errexit

table=${1?Table name is required}
table=${table%.*}
query=${2:-"select * from $table"}
output=${output:-table}


sqlite3 :memory: -cmd '.mode csv' -cmd ".import $table.csv $table" -cmd ".mode $output" "$query"
