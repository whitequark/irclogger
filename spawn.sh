#!/bin/bash

. "$HOME/.rvm/scripts/rvm"

rvm use 1.9.2

thin -C /var/www/irclog.whitequark.org/config.yml start
