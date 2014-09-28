#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use default

bundle exec ./logger.rb </dev/null >/dev/null 2>&1 &
