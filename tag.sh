#!/bin/bash

set -o errexit
[[ "$TRACE" ]] && set -x

echoerr() { echo "$@" 1>&2; }

if [ $# -ne 1 ]; then
  echoerr "Usage: tag.sh <version>"
  exit 1
fi

new_version=${1##v}

if ! grep "$new_version" ./RELEASE_NOTES.md; then
  echoerr "RELEASE_NOTES does not contain a section for $new_version"
  exit 1
fi

# when '# version' found set flag, output lines until next '#'
description=$(awk "/^#.*$new_version/{flag=1;next}/^#/{flag=0}flag" ./RELEASE_NOTES.md)

if ! git diff --quiet HEAD; then
  echoerr "Cannot create release with a dirty repo."
  echoerr "Commit or stash changes and try again."
  git status -sb
  exit 1
fi

current_branch=$(git branch --show-current)
if [[  "$current_branch" != 'main' ]]; then
  current_tag=$(git describe --abbrev=0)
  if [[ "$current_tag" == *"-alpha"* ]]; then
    i=$((${current_tag##*.}+1))
    echo $i
    new_version="${new_version}-alpha.$i"
    echo "Tag already has alpha tag, incrementing:: ${new_version}"
  else
    new_version="${new_version}-alpha.0"
    echo "Tag is on a branch, creating alpha tag: ${new_version}"
  fi
fi

git tag "v${new_version}" -am "Release $new_version" -m "$description"
git push --follow-tags
