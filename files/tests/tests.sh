#!/bin/sh
#
# Shell script to test the MongoDB Docker image.
#
# Copyright 2016-2019, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

BASEDIR=$(dirname $0)

# Variables
MONGODB_TESTS="${BASEDIR}"
MONGODB_VERSION=$(mongod --version | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p')
TESTS_FAIL=0
TESTS_PASS=0
TESTS_TOTAL=0

__MONGODB_DATA__="/data/mongodb"

echo "=== Docker Build Test ==="

# Create temporary dir (if needed)
if ! [[ -d /tmp ]]; then
  mkdir -m 1777 /tmp
fi

echo -n "[TEST] Getting the tests... "
wget -q -O - "https://github.com/mongodb/mongo/archive/r${MONGODB_VERSION}.tar.gz" 2>/dev/null | tar x -zof - -C ${MONGODB_TESTS}/
if [[ "$?" -eq "0" ]]; then
  echo 'OK'
else
  echo 'Failed'
  exit 1
fi

echo -n "[TEST] Starting MongoDB... "
mongod --dbpath ${__MONGODB_DATA__} --fork --logpath ${__MONGODB_DATA__}/mongod.log --setParameter enableTestCommands=1 &>/dev/null
if [[ "$?" -eq "0" ]]; then
  echo 'OK'
else
  echo 'Failed'
  exit 2
fi

start_dir=$(pwd)
cd ${MONGODB_TESTS}
for test in ${MONGODB_TESTS}/mongo-r${MONGODB_VERSION}/jstests/core/*.js; do
  echo -n "[TEST] Running test '$(basename ${test})'... "
  TESTS_TOTAL=$((TESTS_TOTAL+1))
  mongo ${test} &>/dev/null
  if [[ "$?" -eq "0" ]]; then
    echo 'OK'
    TESTS_PASS=$((TESTS_PASS+1))
  else
    echo 'Failed'
    TESTS_FAIL=$((TESTS_FAIL+1))
    #exit 3
  fi
done
cd ${start_dir}
echo "[TEST] Total: ${TESTS_TOTAL} | Pass: ${TESTS_PASS} | Fail: ${TESTS_FAIL}"

echo -n "[TEST] Stoping MongoDB... "
kill -2 $(pgrep mongod) &>/dev/null
if [[ "$?" -eq "0" ]]; then
  echo 'OK'
else
  echo 'Failed'
  exit 4
fi

exit 0
