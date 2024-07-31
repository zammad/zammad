#!/bin/bash

echo "Zammad S/MIME test certificate generation"

# prepare crl stuff
touch /tmp/index.txt
echo 1000 > /tmp/serial

if [[ ! -e "$CERT_DIR/RootCA.key" ]] || [[ ! -e "$CERT_DIR/RootCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="RootCA"

    echo "Generating RootCA.key and RootCA.crt"
    openssl req -batch -config ca.cnf \
        -new -x509 -days 7300 -sha256 -extensions v3_ca -out "${CERT_DIR}/RootCA.crt" \
        -newkey rsa:4096 -nodes -keyout "${CERT_DIR}/RootCA.key" \
        -subj "/emailAddress=RootCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating RootCA.secret"
    cp pass.secret $CERT_DIR/RootCA.secret

    unset CA
fi

if [[ ! -e "$CERT_DIR/IntermediateCA.key" ]] || [[ ! -e "$CERT_DIR/IntermediateCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="RootCA"
    export ICA="IntermediateCA"

    echo "Generating IntermediateCA.key and IntermediateCA.csr"
    openssl req -batch -config intermediate.cnf \
        -new -sha256 -out $CERT_DIR/IntermediateCA.csr \
        -newkey rsa:4096 -nodes -keyout $CERT_DIR/IntermediateCA.key \
        -subj "/emailAddress=IntermediateCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating IntermediateCA.crt"
    openssl ca -batch -config ca.cnf \
        -extensions v3_intermediate_ca -days 7300 -notext -md sha256 \
        -in $CERT_DIR/IntermediateCA.csr -out $CERT_DIR/IntermediateCA.crt

    echo "Generating IntermediateCA.secret"
    cp pass.secret $CERT_DIR/IntermediateCA.secret

    unset CA
    unset ICA
fi

if [[ ! -e "$CERT_DIR/ChainCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    echo "Generating ChainCA.key and ChainCA.csr"
    cp $CERT_DIR/IntermediateCA.key $CERT_DIR/ChainCA.key
    cat $CERT_DIR/IntermediateCA.crt $CERT_DIR/RootCA.crt > $CERT_DIR/ChainCA.crt

    echo "Generating IntermediateCA.secret"
    cp pass.secret $CERT_DIR/ChainCA.secret
fi

for EMAIL_ADDRESS in smime1@example.com smime2@example.com smime3@example.com smimedouble@example.com CaseInsenstive@eXample.COM pgp+smime-sender@example.com pgp+smime-recipient@example.com chain@example.com
do
    if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
    then
        export CA="RootCA"
        export ICA="IntermediateCA"

        echo "Generating $EMAIL_ADDRESS.key"
        openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/${EMAIL_ADDRESS}.key 4096

        echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"
        openssl req -batch -config intermediate.cnf \
            -new -sha256 -out $CERT_DIR/${EMAIL_ADDRESS}.csr \
            -key $CERT_DIR/${EMAIL_ADDRESS}.key -passin file:pass.secret \
            -subj "/emailAddress=${EMAIL_ADDRESS}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

        echo "Generating $EMAIL_ADDRESS.crt (certificate)"

        if [ "$EMAIL_ADDRESS" != "smimedouble@example.com" ]
        then
            SAN="email:${EMAIL_ADDRESS}"
        else
            SAN="email:smimedouble@example.com,email:smimedouble@example.de"
        fi

        export SAN
        openssl ca -batch -config intermediate.cnf \
            -extensions smime -days 7300 -notext -md sha256 \
            -in $CERT_DIR/${EMAIL_ADDRESS}.csr -out $CERT_DIR/${EMAIL_ADDRESS}.crt
        unset SAN

        echo "Generating $EMAIL_ADDRESS.secret"
        cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret

        unset CA
        unset ICA
    fi
done


echo "Generating a combo of private key and certificate for issue #3727"

if [[ ! -e "$CERT_DIR/issue_3727.key" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    cat "$CERT_DIR/smime1@example.com.key" "$CERT_DIR/smime1@example.com.crt" > "$CERT_DIR/issue_3727.key"
    cp "$CERT_DIR/smime1@example.com.secret" "$CERT_DIR/issue_3727.secret"

    # Get SHA1 fingerprint of the certificate, in lowercase.
    openssl x509 -fingerprint -sha1 -noout -in "$CERT_DIR/smime1@example.com.crt" | sed -r 's/.*=([0-9A-F:]{59})/\1/' | sed 's/://g' | tr '[:upper:]' '[:lower:]' > "$CERT_DIR/issue_3727.fingerprint"
fi


echo "Generating expired"
FAKETIME=-10y date

if [[ ! -e "$CERT_DIR/ExpiredCA.key" ]] || [[ ! -e "$CERT_DIR/ExpiredCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="ExpiredCA"

    echo "Generating ExpiredCA.key and ExpiredCA.crt"
    FAKETIME=-10y \
    openssl req -batch -config ca.cnf \
        -new -x509 -days 365 -sha256 -extensions v3_ca -out "${CERT_DIR}/ExpiredCA.crt" \
        -newkey rsa:4096 -nodes -keyout "${CERT_DIR}/ExpiredCA.key" \
        -subj "/emailAddress=ExpiredCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating ExpiredCA.secret"
    cp pass.secret $CERT_DIR/ExpiredCA.secret

    unset CA
fi

if [[ ! -e "$CERT_DIR/ExpiredIntermediateCA.key" ]] || [[ ! -e "$CERT_DIR/ExpiredIntermediateCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="ExpiredCA"
    export ICA="ExpiredIntermediateCA"

    echo "Generating ExpiredIntermediateCA.key and ExpiredIntermediateCA.csr"
    FAKETIME=-10y \
    openssl req -batch -config intermediate.cnf \
        -new -sha256 -out $CERT_DIR/ExpiredIntermediateCA.csr \
        -newkey rsa:4096 -nodes -keyout $CERT_DIR/ExpiredIntermediateCA.key \
        -subj "/emailAddress=ExpiredIntermediateCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating ExpiredIntermediateCA.crt"
    FAKETIME=-10y \
    openssl ca -batch -config ca.cnf \
        -extensions v3_intermediate_ca -days 365 -notext -md sha256 \
        -in $CERT_DIR/ExpiredIntermediateCA.csr -out $CERT_DIR/ExpiredIntermediateCA.crt

    echo "Generating ExpiredIntermediateCA.secret"
    cp pass.secret $CERT_DIR/ExpiredIntermediateCA.secret

    unset CA
    unset ICA
fi

for EMAIL_ADDRESS in expiredsmime1@example.com expiredsmime2@example.com
do
    if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
    then
        export CA="ExpiredCA"
        export ICA="ExpiredIntermediateCA"

        echo "Generating $EMAIL_ADDRESS.key"
        FAKETIME=-10y \
        openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/$EMAIL_ADDRESS.key 4096

        echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"

        FAKETIME=-10y \
        openssl req -batch -config intermediate.cnf \
            -new -sha256 -out $CERT_DIR/${EMAIL_ADDRESS}.csr \
            -key $CERT_DIR/${EMAIL_ADDRESS}.key -passin file:pass.secret \
            -subj "/emailAddress=${EMAIL_ADDRESS}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

        echo "Generating $EMAIL_ADDRESS.crt (certificate)"
        export SAN="email:${EMAIL_ADDRESS}"
        FAKETIME=-10y \
        openssl ca -batch -config intermediate.cnf \
            -extensions smime -days 365 -notext -md sha256 \
            -in $CERT_DIR/${EMAIL_ADDRESS}.csr -out $CERT_DIR/${EMAIL_ADDRESS}.crt
        unset SAN

        echo "Generating $EMAIL_ADDRESS.secret"
        cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret

        unset CA
        unset ICA
    fi
done

if [[ ! -e "$CERT_DIR/SenderCA.key" ]] || [[ ! -e "$CERT_DIR/SenderCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="SenderCA"

    echo "Generating SenderCA.key and SenderCA.crt"
    openssl req -batch -config ca.cnf \
        -new -x509 -days 7300 -sha256 -extensions v3_ca -out "${CERT_DIR}/SenderCA.crt" \
        -newkey rsa:4096 -nodes -keyout "${CERT_DIR}/SenderCA.key" \
        -subj "/emailAddress=SenderCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating SenderCA.secret"
    cp pass.secret $CERT_DIR/SenderCA.secret

    unset CA
fi

if [[ ! -e "$CERT_DIR/SenderIntermediateCA.key" ]] || [[ ! -e "$CERT_DIR/SenderIntermediateCA.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="SenderCA"
    export ICA="SenderIntermediateCA"

    echo "Generating SenderIntermediateCA.key and SenderIntermediateCA.csr"
    openssl req -batch -config intermediate.cnf \
        -new -sha256 -out $CERT_DIR/SenderIntermediateCA.csr \
        -newkey rsa:4096 -nodes -keyout $CERT_DIR/SenderIntermediateCA.key \
        -subj "/emailAddress=SenderIntermediateCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating SenderIntermediateCA.crt"
    openssl ca -batch -config ca.cnf \
        -extensions v3_intermediate_ca -days 7300 -notext -md sha256 \
        -in $CERT_DIR/SenderIntermediateCA.csr -out $CERT_DIR/SenderIntermediateCA.crt

    echo "Generating SenderIntermediateCA.secret"
    cp pass.secret $CERT_DIR/SenderIntermediateCA.secret

    unset CA
    unset ICA
fi

EMAIL_ADDRESS="smime-sender-ca@example.com"

if [[ ! -e "$CERT_DIR/$EMAIL_ADDRESS.crt" ]] || [[ -z "$SKIP_REGENERATE" ]]
then
    export CA="SenderCA"
    export ICA="SenderIntermediateCA"

    echo "Generating $EMAIL_ADDRESS.key"
    openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/${EMAIL_ADDRESS}.key 4096

    echo "Generating $EMAIL_ADDRESS.csr (certificate signing request)"
    openssl req -batch -config intermediate.cnf \
        -new -sha256 -out $CERT_DIR/${EMAIL_ADDRESS}.csr \
        -key $CERT_DIR/${EMAIL_ADDRESS}.key -passin file:pass.secret \
        -subj "/emailAddress=${EMAIL_ADDRESS}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating $EMAIL_ADDRESS.crt (certificate)"

    if [ "$EMAIL_ADDRESS" != "smimedouble@example.com" ]
    then
        SAN="email:${EMAIL_ADDRESS}"
    else
        # special config that contains two email addresses in one certificate
        SAN="email:smimedouble@example.com,email:smimedouble.example.de"
    fi

    export SAN
    openssl ca -batch -config intermediate.cnf \
        -extensions smime -days 7300 -notext -md sha256 \
        -in $CERT_DIR/${EMAIL_ADDRESS}.csr -out $CERT_DIR/${EMAIL_ADDRESS}.crt
    unset SAN

    echo "Generating $EMAIL_ADDRESS.secret"
    cp pass.secret $CERT_DIR/$EMAIL_ADDRESS.secret

    unset CA
    unset ICA
fi

echo "Generating test mails"

for TEST_MAIL_SIGNER in sender_is_signer,smime1@example.com sender_not_signer,smime1@example.com sender_is_signer_with_ca,smime-sender-ca@example.com
do
    TEST_MAIL=${TEST_MAIL_SIGNER%,*}
    TEST_SIGNER=${TEST_MAIL_SIGNER#*,}

    if [[ ! -e "$CERT_DIR/$TEST_MAIL.eml" ]] || [[ -z "$SKIP_REGENERATE" ]]
    then
        if [[ ! -e "$CERT_DIR/$TEST_MAIL.eml.head.txt" ]] || [[ ! -e "$CERT_DIR/$TEST_MAIL.eml.body.txt" ]] || [[ -n "$SKIP_REGENERATE" ]]
        then
            echo "$CERT_DIR/$TEST_MAIL.eml.head.txt or $CERT_DIR/$TEST_MAIL.eml.body.txt not found, skipping..."
            continue
        fi

        if [[ ! -e "$CERT_DIR/$TEST_SIGNER.crt" ]] || [[ ! -e "$CERT_DIR/$TEST_SIGNER.key" ]] || [[ ! -e "$CERT_DIR/$TEST_SIGNER.secret" ]] || [[ -n "$SKIP_REGENERATE" ]]
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
        openssl smime -sign -in "$CERT_DIR/$TEST_MAIL.eml.body.txt" -out "$CERT_DIR/$TEST_MAIL.eml" \
            -signer "$CERT_DIR/$TEST_SIGNER.crt" -inkey "$CERT_DIR/$TEST_SIGNER.key" \
            -certfile "$CERT_DIR/$CERTFILE" -text -passin "file:$CERT_DIR/$TEST_SIGNER.secret"
        cat "$CERT_DIR/$TEST_MAIL.eml.head.txt" "$CERT_DIR/$TEST_MAIL.eml" > /tmp/test_mail && mv /tmp/test_mail "$CERT_DIR/$TEST_MAIL.eml"
    fi
done

echo "Generating further certificates for test variation"

certs=(
    "alice@acme.corp,true,true,false,true,alice@acme.corp+sign+encrypt,rsa"
    "alice@acme.corp,false,true,false,true,alice@acme.corp+encrypt,rsa"
    "alice@acme.corp,true,false,false,true,alice@acme.corp+sign,rsa"
    "alice@acme.corp,true,true,true,true,alice@acme.corp+sign+encrypt+expired,rsa"
    "alice@acme.corp,true,true,true,true,alice@acme.corp+sign+encrypt+ec,ec"
    "alice@acme.corp,true,true,true,false,alice@acme.corp+sign+encrypt+future,rsa"
)

# email sign encrypt expired effective filename algorithm
for cert in "${certs[@]}"; do
    IFS=$',' read -r email sign encrypt expired effective filename algorithm <<< "$cert"

    if [[ -e "$CERT_DIR/$filename.crt" ]] && [[ -n "$SKIP_REGENERATE" ]]
    then
        continue
    fi

    if [ "$sign" == "true" ] && [ "$encrypt" == "true" ]
    then
        KU="nonRepudiation, digitalSignature, keyEncipherment"
    elif [ "$sign" == "true" ]
    then
        KU="nonRepudiation, digitalSignature"
    elif [ "$encrypt" == "true" ]
    then
        KU="keyEncipherment"
    fi

    FAKETIME=""
    if [ "$expired" == "true" ]
    then
        FAKETIME=-10y
    fi

    if [ "$effective" == "false" ]
    then
        FAKETIME=+10y
    fi

    echo "Generating $filename.key"
    if [ "$algorithm" == "ec" ]
    then
        openssl genpkey -algorithm EC \
            -pkeyopt ec_paramgen_curve:prime192v1 \
            -pkeyopt ec_param_enc:named_curve \
            -out $CERT_DIR/${filename}.key -pass file:pass.secret
    else
        openssl genrsa -aes256 -passout file:pass.secret -out $CERT_DIR/${filename}.key 4096
    fi

    echo "Generating $filename.csr (certificate signing request)"
    openssl req -batch -config intermediate.cnf \
        -new -sha256 -out $CERT_DIR/${filename}.csr \
        -key $CERT_DIR/${filename}.key -passin file:pass.secret \
        -subj "/emailAddress=${email}/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com"

    echo "Generating $filename.crt (certificate)"
    export SAN="email:${email}"
    export KU
    export FAKETIME
    openssl ca -batch -config intermediate.cnf \
        -extensions smime -days 3285 -notext -md sha256 \
        -in $CERT_DIR/${filename}.csr -out $CERT_DIR/${filename}.crt
    unset SAN
    unset KU
    unset FAKETIME

    echo "Generating $filename.secret"
    cp pass.secret $CERT_DIR/$filename.secret

    # get rid of crl stuff because of email reusage
    rm -f /tmp/*
    touch /tmp/index.txt
    echo 1000 > /tmp/serial
    rm -f $CERT_DIR/*.pem
done


# cleanup serial number named certificate copies
rm -f $CERT_DIR/*.pem

# run command passed to docker run
exec "$@"
