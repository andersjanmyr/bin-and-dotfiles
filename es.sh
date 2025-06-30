#!/bin/bash

url=${ES_URL:-$ES_PROD6}
tmp_dir=${TMP:-"./tmp"}
full=
if [[ "$1" == "-f" ]]; then
    full=true
fi

elastic() {
    echo "curl -k --fail --silent -Hcontent-type:application/json $url$@" 1>&2
    curl -k --fail --silent -Hcontent-type:application/json $url$@
}

elastic $@
