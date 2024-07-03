#!/bin/bash

set -e

TMP_FILE_BEFORE='./tmp/serialized-graphql-api.ts.before'
TMP_FILE_AFTER='./tmp/serialized-graphql-api.ts.after'

# Delete files on exit
trap 'rm -f $TMP_FILE_BEFORE $TMP_FILE_AFTER' EXIT

function serialize_graphql_api() {
  TARGET_FILE=$1
  INTROSPECTION_FILE='app/graphql/graphql_introspection.json'
  TYPES_FILE='./app/frontend/shared/graphql/types.ts'
  API_FILES=$(find ./app/frontend -path '*/graphql/*' -name '*.api.ts')
  cat $INTROSPECTION_FILE $TYPES_FILE $API_FILES > $TARGET_FILE
}

echo "Checking if auto-generated GraphQL API is up-to-date…"
serialize_graphql_api $TMP_FILE_BEFORE
pnpm generate-graphql-api
serialize_graphql_api $TMP_FILE_AFTER
if ! cmp $TMP_FILE_BEFORE $TMP_FILE_AFTER
then
  diff $TMP_FILE_BEFORE $TMP_FILE_AFTER
  echo "Use the command 'pnpm run generate-graphql-api' to re-generate the API files."
  exit 1
else
  echo "API files are up-to-date."
fi
