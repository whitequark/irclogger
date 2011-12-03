#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use 1.9.3

thin -C /var/www/irclog.whitequark.org/config/thin.yml start
