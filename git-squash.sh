#!/bin/bash

branch=${1?'branch is required'}

git merge --squash $branch
git commit -m "$branch squashed"
