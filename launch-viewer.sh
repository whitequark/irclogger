#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use default

bundle exec thin -C `dirname $0`/config/thin.yml start
