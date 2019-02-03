#!/bin/bash

# Script to start the CMS service. 
# This script is copied to the docker image and run inside container.

set -e

dockerize -wait tcp://db:5432 -timeout 10s

echo "Starting log service ..."
cmsLogService 0 &

echo "Starting CMS services ..."
cmsResourceService -a ALL
