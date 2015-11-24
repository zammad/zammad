#!/bin/bash
DBENV=$1
DBNAME=$2
DBFILE=config/database.yml

echo "Creating $DBFILE for tests with dbname $DBNAME"

echo "$DBENV:" >> $DBFILE
echo "  adapter: mysql2" >> $DBFILE
echo "  database: $DBNAME" >> $DBFILE
echo "  pool: 50" >> $DBFILE
echo "  timeout: 5000" >> $DBFILE
echo "  encoding: utf8" >> $DBFILE
echo "  username: root" >> $DBFILE
echo "  password:" >> $DBFILE
