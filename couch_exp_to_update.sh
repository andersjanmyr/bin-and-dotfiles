#!/usr/bin/env bash
# Converts a couch document to a format that can be updated with /_bulk_docs
# The files are split into 10 000 line chunks and put inside the out_dir.
# couch_exp_to_update.sh <exp_file> [out_dir=.]
#
set -o errexit

exp_file=${1?exported file is required}
out_dir=${2:-.}
mkdir -p $out_dir
tmp_file=$out_dir/exp_imp.tmp
if [[ ! -f $tmp_file ]]; then
    cat $1 | jq -c '.rows[].doc' > $tmp_file
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
