#!/bin/bash

# To generate a self-signed certificate, you will need mkcert installed:
# Please visit https://github.com/FiloSottile/mkcert#installation

# You can generate certificate for a custom domain by passing down the domain/IP as an argument
# and you can also use $ZAMMAD_BIND_IP

# ./generate-ssl.sh 194.23.42.1
# ZAMMAD_BIND_IP=194.23.42.1 ./generate-ssl.sh

mkcert -cert-file localhost.crt -key-file localhost.key localhost 127.0.0.1 $ZAMMAD_BIND_IP $1
mkcert -install

mkdir -p config/ssl

mv localhost.key config/ssl/localhost.key
mv localhost.crt config/ssl/localhost.crt
