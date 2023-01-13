#!/bin/bash

echo "Zammad S/MIME test certificate generation"

if [[ ! -e "$CERT_DIR/RootCA.key" ]] || [[ ! -e "$CERT_DIR/RootCA.crt" ]]
then
  echo "Generating RootCA.key and RootCA.csr"
  openssl req -new -newkey rsa:4096 -nodes -out $CERT_DIR/RootCA.csr -keyout $CERT_DIR/RootCA.key -extensions v3_ca  -subj "/emailAddress=RootCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating RootCA.crt"
  openssl x509 -signkey $CERT_DIR/RootCA.key -days 73000 -req -in $CERT_DIR/RootCA.csr -set_serial 01 -out $CERT_DIR/RootCA.crt

  echo "Generating RootCA.secret"
  cp pass.secret $CERT_DIR/RootCA.secret
fi

if [[ ! -e "$CERT_DIR/IntermediateCA.key" ]] || [[ ! -e "$CERT_DIR/IntermediateCA.crt" ]]
then
  echo "Generating IntermediateCA.key and IntermediateCA.csr"
  openssl req -new -newkey rsa:4096 -nodes -out $CERT_DIR/IntermediateCA.csr -keyout $CERT_DIR/IntermediateCA.key -subj "/emailAddress=IntermediateCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating IntermediateCA.crt"
  openssl x509 -CA $CERT_DIR/RootCA.crt -CAkey $CERT_DIR/RootCA.key -passin file:pass.secret -days 73000 -req -in $CERT_DIR/IntermediateCA.csr -set_serial 02 -out $CERT_DIR/IntermediateCA.crt

  echo "Generating IntermediateCA.secret"
  cp pass.secret $CERT_DIR/IntermediateCA.secret
fi

if [[ ! -e "$CERT_DIR/ChainCA.key" ]] || [[ ! -e "$CERT_DIR/ChainCA.crt" ]]
then
  echo "Generating ChainCA.key and ChainCA.csr"
  openssl req -new -newkey rsa:4096 -nodes -out $CERT_DIR/ChainCA.csr -keyout $CERT_DIR/ChainCA.key -subj "/emailAddress=ChainCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating ChainCA.crt"
  openssl x509 -CA $CERT_DIR/IntermediateCA.crt -CAkey $CERT_DIR/IntermediateCA.key -passin file:pass.secret -days 73000 -req -in $CERT_DIR/ChainCA.csr -set_serial 03 -out $CERT_DIR/ChainCA.crt

  echo "Generating ChainCA.secret"
  cp pass.secret $CERT_DIR/ChainCA.secret
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
        -CA $CERT_DIR/RootCA.crt \
        -CAkey $CERT_DIR/RootCA.key \
        -out $CERT_DIR/$EMAIL_ADDRESS.crt \
        -addtrust emailProtection \
        -addreject clientAuth \
        -addreject serverAuth \
        -trustout \
        -CAcreateserial -CAserial /tmp/RootCA.seq \
        -extensions smime \
        -extfile "$extfile" \
        -passin file:pass.secret

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
  fi
done

echo "Generating a combo of private key and certificate for issue #3727"

if [[ ! -e "$CERT_DIR/issue_3727.key" ]]
then
  cat "$CERT_DIR/smime1@example.com.key" "$CERT_DIR/smime1@example.com.crt" > "$CERT_DIR/issue_3727.key"
  cp "$CERT_DIR/smime1@example.com.secret" "$CERT_DIR/issue_3727.secret"

  # Get SHA1 fingerprint of the certificate, in lowercase.
  openssl x509 -fingerprint -sha1 -noout -in "$CERT_DIR/smime1@example.com.crt" | sed -r 's/.*=([0-9A-F:]{59})/\1/' | sed 's/://g' | tr '[:upper:]' '[:lower:]' > "$CERT_DIR/issue_3727.fingerprint"
fi

echo "Generating from CA chain"
# shellcheck disable=SC2043
for EMAIL_ADDRESS in chain@example.com
do
  if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]]
  then
    echo "Generating $EMAIL_ADDRESS.key"
    openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.key 4096

    echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"
    openssl req -new -key $CERT_DIR/$EMAIL_ADDRESS.key -passin file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.csr -subj "/emailAddress=$EMAIL_ADDRESS/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating $EMAIL_ADDRESS.crt (certificate)"


    openssl x509 -req \
        -days 73000 \
        -in $CERT_DIR/$EMAIL_ADDRESS.csr \
        -CA $CERT_DIR/ChainCA.crt \
        -CAkey $CERT_DIR/ChainCA.key \
        -out $CERT_DIR/$EMAIL_ADDRESS.crt \
        -addtrust emailProtection \
        -addreject clientAuth \
        -addreject serverAuth \
        -trustout \
        -CAcreateserial -CAserial /tmp/ChainCA.seq \
        -extensions smime \
        -extfile "config.cnf" \
        -passin file:pass.secret

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
  fi
done

echo "Generating expired"
FAKETIME=-10y date

if [[ ! -e "$CERT_DIR/ExpiredCA.key" ]] || [[ ! -e "$CERT_DIR/ExpiredCA.crt" ]]
then
  echo "Generating ExpiredCA.key"
  FAKETIME=-10y openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/ExpiredCA.key 4096

  echo "Generating ExpiredCA.crt"
  FAKETIME=-10y openssl req -new -x509 -days 1 -key $CERT_DIR/ExpiredCA.key -passin file:pass.secret -out $CERT_DIR/ExpiredCA.crt -subj "/emailAddress=ExpiredCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

  echo "Generating ExpiredCA.secret"
  cp pass.secret $CERT_DIR/ExpiredCA.secret
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
        -CA $CERT_DIR/ExpiredCA.crt \
        -CAkey $CERT_DIR/ExpiredCA.key \
        -out $CERT_DIR/$EMAIL_ADDRESS.crt \
        -addtrust emailProtection \
        -addreject clientAuth \
        -addreject serverAuth \
        -trustout \
        -CAcreateserial -CAserial /tmp/ExpiredCA.seq \
        -extensions smime \
        -extfile config.cnf \
        -passin file:pass.secret

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
  fi
done

echo "Generating sender CA certificate"

if [[ ! -e "$CERT_DIR/SenderCA.key" ]] || [[ ! -e "$CERT_DIR/SenderCA.crt" ]]
then
  echo "Generating SenderCA.key and SenderCA.crt"
  openssl req -x509 -new -nodes -days 73000 -keyout $CERT_DIR/SenderCA.key -passout file:pass.secret -out $CERT_DIR/SenderCA.crt -config sender_ca.cnf

  echo "Generating SenderCA.secret"
  cp pass.secret $CERT_DIR/SenderCA.secret
fi

echo "Generating sender certificate (with CA)"

EMAIL_ADDRESS="smime-sender-ca@example.com"

if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]]
then
  echo "Generating $EMAIL_ADDRESS.key and $EMAIL_ADDRESS.csr (certificate signing request)"
  openssl req -new -keyout $CERT_DIR/$EMAIL_ADDRESS.key -passout file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.csr -config sender.cnf

  echo "Generating $EMAIL_ADDRESS.crt (certificate)"
  openssl x509 -req -days 73000 -in $CERT_DIR/$EMAIL_ADDRESS.csr -CA $CERT_DIR/SenderCA.crt -CAkey $CERT_DIR/SenderCA.key -CAcreateserial -CAserial /tmp/SenderCA.seq -out $CERT_DIR/$EMAIL_ADDRESS.crt -addtrust emailProtection -addreject clientAuth -addreject serverAuth -trustout -extensions v3_ca -extfile v3_ca.cnf -passin file:pass.secret

  echo "Generating $EMAIL_ADDRESS.secret"
  cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret
fi

echo "Generating test mails"

for TEST_MAIL_SIGNER in sender_is_signer,smime1@example.com sender_not_signer,smime1@example.com sender_is_signer_with_ca,smime-sender-ca@example.com
do
  TEST_MAIL=${TEST_MAIL_SIGNER%,*}
  TEST_SIGNER=${TEST_MAIL_SIGNER#*,}

  if [[ ! -e "$CERT_DIR/$TEST_MAIL.eml" ]]
  then
    if [[ ! -e "$CERT_DIR/$TEST_MAIL.eml.head.txt" ]] || [[ ! -e "$CERT_DIR/$TEST_MAIL.eml.body.txt" ]]
    then
      echo "$CERT_DIR/$TEST_MAIL.eml.head.txt or $CERT_DIR/$TEST_MAIL.eml.body.txt not found, skipping..."
      continue
    fi

    if [[ ! -e "$CERT_DIR/$TEST_SIGNER.crt" ]] || [[ ! -e "$CERT_DIR/$TEST_SIGNER.key" ]] || [[ ! -e "$CERT_DIR/$TEST_SIGNER.secret" ]]
    then
      echo "$CERT_DIR/$TEST_SIGNER.secret or $CERT_DIR/$TEST_SIGNER.secret or $CERT_DIR/$TEST_SIGNER.secret not found, skipping..."
      continue
    fi

    if [ $TEST_SIGNER != "smime-sender-ca@example.com" ]
    then
      CERTFILE="RootCA.crt"
    else
      CERTFILE="SenderCA.crt"
    fi

    echo "Generating $CERT_DIR/$TEST_MAIL.eml"
    openssl smime -sign -in "$CERT_DIR/$TEST_MAIL.eml.body.txt" -out "$CERT_DIR/$TEST_MAIL.eml" -signer "$CERT_DIR/$TEST_SIGNER.crt" -inkey "$CERT_DIR/$TEST_SIGNER.key" -certfile "$CERT_DIR/$CERTFILE" -text -passin "file:$CERT_DIR/$TEST_SIGNER.secret"
    cat "$CERT_DIR/$TEST_MAIL.eml.head.txt" "$CERT_DIR/$TEST_MAIL.eml" > /tmp/test_mail && mv /tmp/test_mail "$CERT_DIR/$TEST_MAIL.eml"
  fi
done

# run command passed to docker run
exec "$@"
