#!/bin/bash

if [ "$RNAME" == '' ]; then
  echo "ERROR: Env RNAME is missing!"
  exit 1
fi

DBNAME=$RNAME
DBFILE=config/database.yml
DB_PRODUCTION=$DBNAME"_production"
DB_TEST=$DBNAME"_test"
DB_DEVELOPMENT=$DBNAME"_development"

echo "Creating $DBFILE for tests with $DBNAME"

echo "production:" > $DBFILE
echo "  adapter: mysql2" >> $DBFILE
echo "  database: $DB_PRODUCTION" >> $DBFILE
echo "  pool: 50" >> $DBFILE
echo "  timeout: 5000" >> $DBFILE
echo "  encoding: utf8" >> $DBFILE
echo "  username: root" >> $DBFILE
echo "  password:" >> $DBFILE
echo "test:" >> $DBFILE
echo "  adapter: mysql2" >> $DBFILE
echo "  database: $DB_TEST" >> $DBFILE
echo "  pool: 50" >> $DBFILE
echo "  timeout: 5000" >> $DBFILE
echo "  encoding: utf8" >> $DBFILE
echo "  username: root" >> $DBFILE
echo "  password:" >> $DBFILE
echo "development:" >> $DBFILE
echo "  adapter: mysql2" >> $DBFILE
echo "  database: $DB_DEVELOPMENT" >> $DBFILE
echo "  pool: 50" >> $DBFILE
echo "  timeout: 5000" >> $DBFILE
echo "  encoding: utf8" >> $DBFILE
echo "  username: root" >> $DBFILE
echo "  password:" >> $DBFILE
