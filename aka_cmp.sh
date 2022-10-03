#!/bin/bash

set -o errexit

paths=$(cat <<-EOT
/gb/en/local-extensions/header-footer/style-extensions-fragment-recursive.html?request-path=/se/sv/index.html
/gb/en/index.html
EOT
)

hosts="www.ikea.com fragments.cdn.ingka.com"


aka_curl() {
  curl -v \
    -H "x-ikea-secret: $X_IKEA_SECRET" \
    -H 'Pragma: akamai-x-get-true-cache-key' \
    -H 'x-aka-debug: true' \
    $1
}

for p in $paths; do
  for h in $hosts; do
    url="https://$h$p"
    aka_curl "$url" 2>&1 | egrep -i '^[<].*true-cache'| awk '{ print $3 }' > $h.key
  done
  if ! diff *.key; then
    echo $path
  fi
done
