#!/bin/bash

if [ "`uname`" = "Darwin" ] ; then
  unset GEM_PATH GEM_HOME; /usr/local/bin/mvim -v "$@"
else
  unset GEM_PATH GEM_HOME; /usr/bin/vim  "$@"
fi

