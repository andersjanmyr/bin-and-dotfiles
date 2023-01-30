#!/bin/bash

if [ "`uname`" = "Darwin" ] ; then
  unset GEM_PATH GEM_HOME; /usr/local/bin/nvim -u ~/.config/nvim/init.lua "$@"
else
  unset GEM_PATH GEM_HOME; /usr/bin/vim  "$@"
fi

