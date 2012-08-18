#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use 1.9.3 >/dev/null

./checker.rb
