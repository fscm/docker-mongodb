#!/bin/bash
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

/bin/echo "=== Docker Build Test ==="

# Create temporary dir (if needed)
if ! [[ -d /tmp ]]; then
  mkdir -m 1777 /tmp
fi

/bin/echo -n "[TEST] Getting the tests... "
curl -sL --retry 3 --insecure "https://github.com/mongodb/mongo/archive/r${MONGODB_VERSION}.tar.gz" | tar -xz --no-same-owner --strip-components=1 -C ${MONGODB_TESTS}/ --wildcards mongo-*/jstests
if [[ "$?" -eq "0" ]]; then
  /bin/echo 'OK'
else
  /bin/echo 'Failed'
  exit 1
fi

/bin/echo -n "[TEST] Starting MongoDB... "
mongod --dbpath ${__MONGODB_DATA__} --fork --logpath ${__MONGODB_DATA__}/mongod.log --setParameter enableTestCommands=1 &>/dev/null
if [[ "$?" -eq "0" ]]; then
  /bin/echo 'OK'
else
  /bin/echo 'Failed'
  exit 2
fi

start_dir=$(pwd)
cd ${MONGODB_TESTS}
for test in ${MONGODB_TESTS}/jstests/core/*.js; do
  /bin/echo -n "[TEST] Running test '$(basename ${test})'... "
  TESTS_TOTAL=$((TESTS_TOTAL+1))
  mongo ${test} &>/dev/null
  if [[ "$?" -eq "0" ]]; then
    /bin/echo 'OK'
    TESTS_PASS=$((TESTS_PASS+1))
  else
    /bin/echo 'Failed'
    TESTS_FAIL=$((TESTS_FAIL+1))
    #exit 3
  fi
done
cd ${start_dir}
/bin/echo "[TEST] Total: ${TESTS_TOTAL} | Pass: ${TESTS_PASS} | Fail: ${TESTS_FAIL}"

/bin/echo -n "[TEST] Stoping MongoDB... "
kill -2 $(pgrep mongod) &>/dev/null
if [[ "$?" -eq "0" ]]; then
  /bin/echo 'OK'
else
  /bin/echo 'Failed'
  exit 4
fi

exit 0
