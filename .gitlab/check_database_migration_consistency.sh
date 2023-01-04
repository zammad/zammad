#!/bin/bash

set -e

TMP_FILE_BEFORE='./tmp/before-migration-dump.json'
TMP_FILE_AFTER='./tmp/after-migration-dump.json'

echo "Checking if data is still the same after migration..."
if ! cmp $TMP_FILE_BEFORE $TMP_FILE_AFTER
then
  echo "Data mismatch after migration."
  diff $TMP_FILE_BEFORE $TMP_FILE_AFTER
  exit 1
else
  echo "Migration was successful."
fi
