#!/bin/bash

set -o errexit

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <table> [query]"
  echo "option: output=<one of>"
  sqlite3 :memory: -cmd '.help mode' .exit
  exit 1
fi
table=${1?Table name is required}
table=${table%.*}
query=${2:-"select * from $table"}
output=${output:-table}


sqlite3 :memory: -cmd '.mode csv' -cmd ".import $table.csv $table" -cmd ".mode $output" "$query"
