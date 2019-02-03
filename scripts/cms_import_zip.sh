#!/bin/bash

# Script to import a zip-ed contest directory.
# This script is copied to the docker image and run inside container.

set -e

dockerize -wait tcp://db:5432 -timeout 10s

ZIP_FILE=$1
CONTEST_NAME=$2
CONTEST_DIR=/tmp/contest/${CONTEST_NAME}

echo "Unpacking ..."
mkdir -p "${CONTEST_DIR}"
unzip "${ZIP_FILE}" -d "${CONTEST_DIR}"

echo "Importing ..."
cd "${CONTEST_DIR}"
cmsImportContest --update-contest --import-tasks --update-tasks .