#!/usr/bin/env bash

set -eux

echo "
[ ca ]
# January 1, 2015
default_startdate = 2015010360000Z

[ req ]
distinguished_name = req_distinguished_name

[ req_distinguished_name ]
# If this isn't set, the error is "error, no objects specified in config file"
commonName = Common Name (hostname, IP, or your name)

countryName_default            = US
stateOrProvinceName_default    = CA
localityName_default           = San Francisco
0.organizationName_default     = mysql2_gem
organizationalUnitName_default = Mysql2Gem
emailAddress_default           = mysql2gem@example.com
" | tee ca.cnf cert.cnf

# The client and server certs must have a diferent common name than the CA
# to avoid "SSL connection error: error:00000001:lib(0):func(0):reason(1)"

echo "
commonName_default             = ca_mysql2gem
" >> ca.cnf

echo "
commonName_default             = mysql2gem.example.com
" >> cert.cnf

# Generate a set of certificates
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -nodes -days 3600 -key ca-key.pem -out ca-cert.pem -batch -config ca.cnf
openssl req -newkey rsa:2048 -days 3600 -nodes -keyout pkcs8-server-key.pem -out server-req.pem -batch -config cert.cnf
openssl x509 -req -in server-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
openssl req -newkey rsa:2048 -days 3600 -nodes -keyout pkcs8-client-key.pem -out client-req.pem -batch -config cert.cnf
openssl x509 -req -in client-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

# Convert format from PKCS#8 to PKCS#1
openssl rsa -in pkcs8-server-key.pem -out server-key.pem
openssl rsa -in pkcs8-client-key.pem -out client-key.pem

echo "done"
