#!/bin/sh

echo "Zammad S/MIME test certificate generation"

if [[ ! -e "$CERT_DIR/ca.key" ]] || [[ ! -e "$CERT_DIR/ca.crt" ]]
then
  echo "Generating ca.key"
  openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/ca.key 4096

  echo "Generating ca.crt"
  openssl req -new -x509 -days 73000 -key $CERT_DIR/ca.key -passin file:pass.secret -out $CERT_DIR/ca.crt -subj "/emailAddress=ca@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating ca.secret"
  cp pass.secret $CERT_DIR/ca.secret
fi

for EMAIL_ADDRESS in smime1@example.com smime2@example.com smime3@example.com smimedouble@example.com CaseInsenstive@eXample.COM
do
  if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]]
  then
    echo "Generating $EMAIL_ADDRESS.key"
    openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.key 4096

    echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"
    openssl req -new -key $CERT_DIR/$EMAIL_ADDRESS.key -passin file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.csr -subj "/emailAddress=$EMAIL_ADDRESS/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating $EMAIL_ADDRESS.crt (certificate)"

    if [ "$EMAIL_ADDRESS" != "smimedouble@example.com" ]
    then
      extfile="config.cnf"
    else
      # special config that contains two email addresses in one certificate
      extfile="double.cnf"
    fi

    openssl x509 -req \
        -days 73000 \
        -in $CERT_DIR/$EMAIL_ADDRESS.csr \
        -CA $CERT_DIR/ca.crt \
        -CAkey $CERT_DIR/ca.key \
        -out $CERT_DIR/$EMAIL_ADDRESS.crt \
        -addtrust emailProtection \
        -addreject clientAuth \
        -addreject serverAuth \
        -trustout \
        -CAcreateserial -CAserial /tmp/ca.seq \
        -extensions smime \
        -extfile "$extfile" \
        -passin file:pass.secret

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
  fi
done

echo "Generating expired"
FAKETIME=-10y date

if [[ ! -e "$CERT_DIR/expiredca.key" ]] || [[ ! -e "$CERT_DIR/expiredca.crt" ]]
then
  echo "Generating expiredca.key"
  FAKETIME=-10y openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/expiredca.key 4096

  echo "Generating expiredca.crt"
  FAKETIME=-10y openssl req -new -x509 -days 1 -key $CERT_DIR/expiredca.key -passin file:pass.secret -out $CERT_DIR/expiredca.crt -subj "/emailAddress=expiredca@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating expiredca.secret"
  cp pass.secret $CERT_DIR/expiredca.secret
fi

for EMAIL_ADDRESS in expiredsmime1@example.com expiredsmime2@example.com
do
  if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]]
  then
    echo "Generating $EMAIL_ADDRESS.key"
    FAKETIME=-10y openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.key 4096

    echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"
    FAKETIME=-10y openssl req -new -key $CERT_DIR/$EMAIL_ADDRESS.key -passin file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.csr -subj "/emailAddress=$EMAIL_ADDRESS/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating $EMAIL_ADDRESS.crt (certificate)"
    FAKETIME=-10y openssl x509 -req \
        -days 1 \
        -in $CERT_DIR/$EMAIL_ADDRESS.csr \
        -CA $CERT_DIR/expiredca.crt \
        -CAkey $CERT_DIR/expiredca.key \
        -out $CERT_DIR/$EMAIL_ADDRESS.crt \
        -addtrust emailProtection \
        -addreject clientAuth \
        -addreject serverAuth \
        -trustout \
        -CAcreateserial -CAserial /tmp/expiredca.seq \
        -extensions smime \
        -extfile config.cnf \
        -passin file:pass.secret

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
  fi
done

# run command passed to docker run
exec "$@"
