#!/usr/bin/env bash
# Converts a couch document to a format that can be deleted with /_bulk_docs
# The files are split into 10 000 line chunks and put inside the out_dir.
# couch_exp_to_imp.sh <exp_file> [out_dir=.]
#
set -o errexit

exp_file=${1?exported file is required}
out_dir=${2:-.}
mkdir -p $out_dir
tmp_file=$out_dir/exp_del.tmp

cat $exp_file | jq -c '.rows[] | { _id: .id, _rev: .value.rev, "_deleted": true }' > $tmp_file

if [[ ! -s $tmp_file ]]; then
    echo "No rows in $exp_file" 2>&1
    exit 1
fi

split -l 10000 $tmp_file $out_dir/

for f in $out_dir/??; do
    path=$f.json
    echo '{
    "docs": [' > $path
    cat $f | sed '$!s/$/,/' >> $path
    echo ']
    }' >> $path
done

rm $out_dir/??
rm $tmp_file
