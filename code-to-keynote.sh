#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage $0 <filename>"
  exit 1
fi
highlight -O rtf $1 --font-size 32 --font Inconsolata --style solarized-dark -W -J 50 -j 3
