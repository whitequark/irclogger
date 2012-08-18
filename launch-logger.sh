#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use 1.9.3

./logger.rb </dev/null >/dev/null 2>&1 &
