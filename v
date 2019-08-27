#!/bin/bash

if [ "`uname`" = "Darwin" ] ; then
  unset GEM_PATH GEM_HOME; /usr/local/bin/nvim -u ~/.vimrc "$@"
else
  unset GEM_PATH GEM_HOME; /usr/bin/vim  "$@"
fi

