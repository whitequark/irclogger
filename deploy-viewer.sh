#!/bin/bash

git pull && kill `cat tmp/viewer.pid` && kill `cat tmp/viewer.pid` && ./launch-viewer.sh
