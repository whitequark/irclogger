#!/bin/bash

git pull && kill `cat tmp/logger.pid` && ./launch-logger.sh
