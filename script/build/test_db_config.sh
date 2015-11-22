#!/bin/bash
DBNAME=$1
DBFILE=config/database.yml2

echo "Creating $DBFILE for tests with dbname $DBNAME"

echo "test:" > $DBFILE
echo "  adapter: mysql2" >> $DBFILE
echo "  database: $DBNAME" >> $DBFILE
echo "  pool: 50" >> $DBFILE
echo "  timeout: 5000" >> $DBFILE
echo "  encoding: utf8" >> $DBFILE
echo "  username: root" >> $DBFILE
echo "  password:" >> $DBFILE
