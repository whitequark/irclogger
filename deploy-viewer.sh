#!/bin/bash

set -e

git pull
bundle
kill `cat tmp/viewer.pid`
kill `cat tmp/viewer.pid` # because persistent connections
./launch-viewer.sh
