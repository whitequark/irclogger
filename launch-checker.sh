#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use default >/dev/null

./checker.rb
