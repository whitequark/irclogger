#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use 1.9.3

bundle exec thin -C `dirname $0`/config/thin.yml start
