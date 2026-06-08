#!/bin/sh

set -eu

CERT_DIR=/tmp/docker-mailserver/certs
CONFIG_DIR=/tmp/docker-mailserver
CERT_FILE="$CERT_DIR/mail.test.local.crt"
KEY_FILE="$CERT_DIR/mail.test.local.key"
POSTFIX_ACCOUNTS_FILE="$CONFIG_DIR/postfix-accounts.cf"
POSTFIX_VIRTUAL_FILE="$CONFIG_DIR/postfix-virtual.cf"
POSTFIX_MAIN_FILE="$CONFIG_DIR/postfix-main.cf"

mkdir -p "$CERT_DIR"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=mail.test.local" \
    -addext "subjectAltName=DNS:mail.test.local,DNS:localhost"
fi

if [ ! -f "$POSTFIX_ACCOUNTS_FILE" ]; then
  touch "$POSTFIX_ACCOUNTS_FILE"
  setup email add zammad@test.local zammad
elif ! setup email list | grep -q 'zammad@test.local$'; then
  setup email add zammad@test.local zammad
fi

if [ ! -f "$POSTFIX_VIRTUAL_FILE" ]; then
  touch "$POSTFIX_VIRTUAL_FILE"
  setup alias add zammad@localhost zammad@test.local
elif ! setup alias list | grep -q 'zammad@localhost'; then
  setup alias add zammad@localhost zammad@test.local
fi

cat > "$POSTFIX_MAIN_FILE" <<'EOF'
smtpd_recipient_restrictions = permit_sasl_authenticated,reject
relay_transport = discard:
default_transport = discard:
EOF
