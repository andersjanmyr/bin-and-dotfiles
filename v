#!/bin/bash

if [ "`uname`" = "Darwin" ] ; then
  unset GEM_PATH GEM_HOME; /usr/local/bin/nvim "$@"
else
  unset GEM_PATH GEM_HOME; /usr/bin/vim  "$@"
fi

