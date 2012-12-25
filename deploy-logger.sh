#!/bin/bash

set -e

git pull
bundle
kill `cat tmp/logger.pid`
./launch-logger.sh
