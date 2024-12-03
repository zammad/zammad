#!/bin/bash

GNUPGHOME=$(mktemp -d)
export GNUPGHOME

echo "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed" > "$GNUPGHOME/gpg.conf"

trap 'rm -rf $GNUPGHOME' EXIT

BASEDIR=$(dirname "$0")
KEY_DIR="$BASEDIR/.."
KEY_PASSPHRASE=zammad
KEY_ALGO=rsa4096
KEY_USAGE=sign,encr
KEY_EXPIRE=10y
MAIL_DIR="$KEY_DIR/mail/"

echo "Zammad PGP test key generation"

# Don't use dashes (-) in email addresses unless you know what you're doing!
# shellcheck disable=SC2043
for PGP_UID in zammad@localhost pgp1@example.com pgp2@example.com pgp2@example.com-other pgp3@example.com 'Nicole Braun <nicole.braun@zammad.org>' noexpirepgp1@example.com expiredpgp1@example.com ocbpgp1@example.com
do
  echo "Processing key: $PGP_UID"

  echo -n "  Identifying email address... "
  EMAIL_REGEX=$(echo "$PGP_UID" | perl -wlne '/<(.*)>/ and print $1')
  EMAIL_ADDRESS=${EMAIL_REGEX:-$PGP_UID}
  echo "$EMAIL_ADDRESS"

  # Support additional keys.
  PGP_UID=${PGP_UID%-*}
  echo "  Using '$PGP_UID' as UID…"

  KEY_EXPIRE_ARG=$KEY_EXPIRE

  # Support keys without expiration date.
  [[ $PGP_UID =~ ^noexpire ]] && KEY_EXPIRE_ARG=0

  # Support expired keys.
  [[ $PGP_UID =~ ^expired ]] && KEY_EXPIRE_ARG=$(date -u +'%Y%m%dT000000')

  # Support AEAD: OCB keys.
  if [[ $PGP_UID =~ ^ocb ]]; then
    # Support for OCB was added in GPG 2.2.40, it will not work on older versions.
    if printf '%s\n%s\n' "$(gpg --version | head -1 | cut -d' ' -f3)" "2.2.40" | sort -rVC; then
      DEFAULT_PREFERENCE_LIST_ARG=--default-preference-list="AES256,AES192,AES,CAST5,3DES,OCB,SHA512,SHA384,SHA256,SHA224,SHA1,ZLIB,BZIP2,ZIP,Uncompressed,MDC,AEAD"
    else
      echo "  ERROR: GnuPG too old, please update to v2.2.40 or later in order to generate OCB keys."
      echo "  Skipping…"
      continue
    fi
  fi

  echo "  Generating key…"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE $DEFAULT_PREFERENCE_LIST_ARG --quick-generate-key "$PGP_UID" $KEY_ALGO $KEY_USAGE $KEY_EXPIRE_ARG

  echo "  Exporting public key…"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pub.pgp" --export "$PGP_UID"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pub.asc" --armor --export "$PGP_UID"

  echo "  Exporting private key…"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pgp" --export-secret-key "$PGP_UID"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.asc" --armor --export-secret-key "$PGP_UID"

  echo "  Exporting key information…"
  echo -n $KEY_PASSPHRASE > "$KEY_DIR/$EMAIL_ADDRESS.passphrase"

  KEY_INFO=$(gpg --batch --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$EMAIL_ADDRESS.pub.asc")

  KEY_CREATED_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f6)
  echo -n "$(date -d @$KEY_CREATED_AT -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -r $KEY_CREATED_AT -u +'%Y-%m-%dT%H:%M:%SZ')" > "$KEY_DIR/$EMAIL_ADDRESS.created_at"

  KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
  if [ -n "$KEY_EXPIRES_AT" ]; then
    echo -n "$(date -d @$KEY_EXPIRES_AT -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y-%m-%dT%H:%M:%SZ')" > "$KEY_DIR/$EMAIL_ADDRESS.expires_at"
  fi

  KEY_FINGERPRINT=$(echo "$KEY_INFO" | head -n 2 | tail -1 | cut -d: -f10)
  echo -n $KEY_FINGERPRINT > "$KEY_DIR/$EMAIL_ADDRESS.fingerprint"

  # Cleanup.
  echo "  Deleting keys from keyring…"
  gpg --batch --quiet --yes --delete-secret-key $KEY_FINGERPRINT
  gpg --batch --quiet --yes --delete-key $KEY_FINGERPRINT
done

# A key with multiple UIDs.
PGP_UIDS=("Multi PGP2 <multipgp2@example.com>" "Multi PGP1 <multipgp1@example.com>")

echo "Generating key for ${PGP_UIDS[0]}"

gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --quick-generate-key "${PGP_UIDS[0]}" $KEY_ALGO $KEY_USAGE $KEY_EXPIRE

for i in "${!PGP_UIDS[@]}"
do
  if [[ $i -eq 0 ]]; then
    continue
  fi

  echo "  Adding UID ${PGP_UIDS[$i]} to the same key…"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --quick-add-uid "${PGP_UIDS[0]}" "${PGP_UIDS[$i]}"
done

EMAIL_REGEX=$(echo ${PGP_UIDS[0]} | perl -wlne '/<(.*)>/ and print $1')
EMAIL_ADDRESS=${EMAIL_REGEX:-${PGP_UIDS[0]}}

echo "  Exporting public key for $EMAIL_ADDRESS"
gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pub.pgp" --export $EMAIL_ADDRESS
gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pub.asc" --armor --export $EMAIL_ADDRESS

echo "  Exporting private key for $EMAIL_ADDRESS"
gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.pgp" --export-secret-key $EMAIL_ADDRESS
gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --output "$KEY_DIR/$EMAIL_ADDRESS.asc" --armor --export-secret-key $EMAIL_ADDRESS

echo "  Exporting key information for $EMAIL_ADDRESS"
echo -n $KEY_PASSPHRASE > "$KEY_DIR/$EMAIL_ADDRESS.passphrase"

KEY_INFO=$(gpg --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$EMAIL_ADDRESS.pub.asc")

KEY_CREATED_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f6)
echo -n "$(date -d @$KEY_CREATED_AT -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -r $KEY_CREATED_AT -u +'%Y-%m-%dT%H:%M:%SZ')" > "$KEY_DIR/$EMAIL_ADDRESS.created_at"

KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
echo -n "$(date -d @$KEY_EXPIRES_AT -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y-%m-%dT%H:%M:%SZ')" > "$KEY_DIR/$EMAIL_ADDRESS.expires_at"

KEY_FINGERPRINT=$(echo "$KEY_INFO" | head -n 2 | tail -1 | cut -d: -f10)
echo -n $KEY_FINGERPRINT > "$KEY_DIR/$EMAIL_ADDRESS.fingerprint"

echo "Generating signed test mails (detached signature)"

# shellcheck disable=SC2042
for TEST_MAIL_KEY in mail-expired,expiredpgp1@example.com
do
  TEST_MAIL=${TEST_MAIL_KEY%,*}
  EMAIL_ADDRESS=${TEST_MAIL_KEY#*,}

  echo "Processing mail: $TEST_MAIL"

  KEY_INFO=$(gpg --batch --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$EMAIL_ADDRESS.pub.asc")
  KEY_FINGERPRINT=$(echo "$KEY_INFO" | head -n 2 | tail -1 | cut -d: -f10)

  KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
  KEY_EXPIRATION_DATE=$(date -d @$KEY_EXPIRES_AT -R 2>/dev/null || date -r $KEY_EXPIRES_AT -R)
  KEY_EXPIRE_ARG=$(date -d @$KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S')

  echo "  Importing key for $EMAIL_ADDRESS"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$EMAIL_ADDRESS.asc"

  echo "  Computing current date header…"
  echo "Date: $(date -R)" > "$MAIL_DIR/$TEST_MAIL.box"

  # Support expired keys.
  [[ $EMAIL_ADDRESS =~ ^expired ]] && echo "Date: $KEY_EXPIRATION_DATE" > "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Constructing mail body…"
  cat "$MAIL_DIR/$TEST_MAIL.part1.box" "$MAIL_DIR/$TEST_MAIL.part2.box" "$MAIL_DIR/$TEST_MAIL.part3.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Appending message signature…"

  # Support expired keys.
  if [[ $EMAIL_ADDRESS =~ ^expired ]]; then
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --detach-sign --trust-model=always --faked-system-time=$KEY_EXPIRE_ARG --default-key $KEY_FINGERPRINT --sign < "$MAIL_DIR/$TEST_MAIL.part2.box" >> "$MAIL_DIR/$TEST_MAIL.box"
  else
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --detach-sign --trust-model=always --default-key $KEY_FINGERPRINT --sign < "$MAIL_DIR/$TEST_MAIL.part2.box" >> "$MAIL_DIR/$TEST_MAIL.box"
  fi

  echo "  Ending mail file…"
  cat "$MAIL_DIR/$TEST_MAIL.part5.box" >> "$MAIL_DIR/$TEST_MAIL.box"
done

echo "Generating encrypted test mails"

# Don't use dashes (-) in email addresses unless you know what you're doing!
# shellcheck disable=SC2042,SC2258
for TEST_MAIL_SENDER_RECIPIENTS in mail-other-key,pgp1@example.com,pgp2@example.com-other,pgp3@example.com mail-decrypt-expired,pgp1@example.com,expiredpgp1@example.com,expiredpgp1@example.com mail-ocb,pgp1@example.com,ocbpgp1@example.com,pgp3@example.com mail-decrypt-bcc,pgp1@example.com,zammad@localhost,
do
  TEST_MAIL=${TEST_MAIL_SENDER_RECIPIENTS%,*,*,*}
  EMAIL_ADDRESSES=${TEST_MAIL_SENDER_RECIPIENTS#*,}
  SENDER_EMAIL_ADDRESS=${EMAIL_ADDRESSES%,*,*}
  # shellcheck disable=SC2206
  RECIPIENTS=(${EMAIL_ADDRESSES#*,})
  # shellcheck disable=SC2128
  IFS=',' read -r -a RECIPIENT_EMAIL_ADDRESSES <<< "$RECIPIENTS"

  echo "Processing mail: $TEST_MAIL"

  unset RECIPIENTS_ARG
  unset KEY_EXPIRATION_DATE
  unset FAKED_SYSTEM_TIME_ARG
  unset FORCE_OCB_ARG

  for RECIPIENT_EMAIL_ADDRESS in "${RECIPIENT_EMAIL_ADDRESSES[@]}"
  do
    echo "  Importing public key for $RECIPIENT_EMAIL_ADDRESS"
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$RECIPIENT_EMAIL_ADDRESS.pub.asc"

    # Support expired keys.
    if [[ $RECIPIENT_EMAIL_ADDRESS =~ ^expired ]]; then
      KEY_INFO=$(gpg --batch --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$RECIPIENT_EMAIL_ADDRESS.pub.asc")
      KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
      KEY_EXPIRATION_DATE=$(date -d @$KEY_EXPIRES_AT -R 2>/dev/null || date -r $KEY_EXPIRES_AT -R)
      KEY_EXPIRE_ARG=$(date -d @$KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S')
      FAKED_SYSTEM_TIME_ARG="--faked-system-time=$KEY_EXPIRE_ARG"
    fi

    # Support AEAD: OCB keys.
    if [[ $RECIPIENT_EMAIL_ADDRESS =~ ^ocb ]]; then
      # Support for OCB was added in GPG 2.2.40, it will not work on older versions.
      if printf '%s\n%s\n' "$(gpg --version | head -1 | cut -d' ' -f3)" "2.2.40" | sort -rVC; then
        FORCE_OCB_ARG=--force-ocb
      else
        echo "  ERROR: GnuPG too old, please update to v2.3.0 or later in order to generate OCB keys."
        echo "  Skipping…"
        continue 2
      fi
    fi

    SANITIZED_EMAIL_ADDRESS=${RECIPIENT_EMAIL_ADDRESS%-*}
    echo "    Using $SANITIZED_EMAIL_ADDRESS as recipient…"

    RECIPIENTS_ARG="$RECIPIENTS_ARG --recipient $SANITIZED_EMAIL_ADDRESS"
  done

  echo "  Computing current date header…"
  echo "Date: $(date -R)" > "$MAIL_DIR/$TEST_MAIL.box"

  # Support expired keys.
  [[ ! -z $KEY_EXPIRATION_DATE ]] && echo "Date: $KEY_EXPIRATION_DATE" > "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Constructing mail body…"
  cat "$MAIL_DIR/$TEST_MAIL.part1.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Encrypting message…"

  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --trust-model=always $FAKED_SYSTEM_TIME_ARG $FORCE_OCB_ARG $RECIPIENTS_ARG --encrypt < "$MAIL_DIR/$TEST_MAIL.message.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Ending mail file…"
  cat "$MAIL_DIR/$TEST_MAIL.part3.box" >> "$MAIL_DIR/$TEST_MAIL.box"
done

echo "Generating encrypted + signed test mails"

# Don't use dashes (-) in email addresses unless you know what you're doing!
# shellcheck disable=SC2042
for TEST_MAIL_SENDER_RECIPIENTS in mail-detached,pgp1@example.com,pgp2@example.com,pgp3@example.com mail-attached,pgp1@example.com,pgp2@example.com,pgp3@example.com
do
  TEST_MAIL=${TEST_MAIL_SENDER_RECIPIENTS%,*,*,*}
  EMAIL_ADDRESSES=${TEST_MAIL_SENDER_RECIPIENTS#*,}
  SENDER_EMAIL_ADDRESS=${EMAIL_ADDRESSES%,*,*}
  # shellcheck disable=SC2206
  RECIPIENTS=(${EMAIL_ADDRESSES#*,})
  # shellcheck disable=SC2128
  IFS=',' read -r -a RECIPIENT_EMAIL_ADDRESSES <<< "$RECIPIENTS"

  echo "Processing mail: $TEST_MAIL"

  KEY_INFO=$(gpg --batch --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$SENDER_EMAIL_ADDRESS.pub.asc")
  KEY_FINGERPRINT=$(echo "$KEY_INFO" | head -n 2 | tail -1 | cut -d: -f10)

  KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
  KEY_EXPIRATION_DATE=$(date -d @$KEY_EXPIRES_AT -R 2>/dev/null || date -r $KEY_EXPIRES_AT -R)
  KEY_EXPIRE_ARG=$(date -d @$KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S')

  echo "  Importing key for $SENDER_EMAIL_ADDRESS"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$SENDER_EMAIL_ADDRESS.asc"

  echo "  Constructing signed message…"
  SIGNED_MESSAGE_DIR=$(mktemp -d)
  cat "$MAIL_DIR/$TEST_MAIL.message.part1.box" "$MAIL_DIR/$TEST_MAIL.message.part2.box" "$MAIL_DIR/$TEST_MAIL.message.part3.box" > "$SIGNED_MESSAGE_DIR/signed-message"

  echo "  Signing message…"

  DETACH_SIGN_ARG=--detach-sign

  # Support attached signatures.
  [[ $TEST_MAIL =~ -attached$ ]] && unset DETACH_SIGN_ARG

  # Support expired keys.
  if [[ $SENDER_EMAIL_ADDRESS =~ ^expired ]]; then
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor $DETACH_SIGN_ARG --trust-model=always --faked-system-time=$KEY_EXPIRE_ARG --default-key $KEY_FINGERPRINT --sign < "$MAIL_DIR/$TEST_MAIL.message.part2.box" >> "$SIGNED_MESSAGE_DIR/signed-message"
  else
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor $DETACH_SIGN_ARG --trust-model=always --default-key $KEY_FINGERPRINT --sign < "$MAIL_DIR/$TEST_MAIL.message.part2.box" >> "$SIGNED_MESSAGE_DIR/signed-message"
  fi

  echo "  Ending signed message…"
  cat "$MAIL_DIR/$TEST_MAIL.message.part5.box" >> "$SIGNED_MESSAGE_DIR/signed-message"

  echo "  Computing current date header…"
  echo "Date: $(date -R)" > "$MAIL_DIR/$TEST_MAIL.box"

  # Support expired keys.
  [[ $SENDER_EMAIL_ADDRESS =~ ^expired ]] && echo "Date: $KEY_EXPIRATION_DATE" > "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Constructing mail body…"
  cat "$MAIL_DIR/$TEST_MAIL.part1.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  unset RECIPIENTS_ARG

  for RECIPIENT_EMAIL_ADDRESS in "${RECIPIENT_EMAIL_ADDRESSES[@]}"
  do
    echo "  Importing public key for $RECIPIENT_EMAIL_ADDRESS"
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$RECIPIENT_EMAIL_ADDRESS.pub.asc"

    SANITIZED_EMAIL_ADDRESS=${RECIPIENT_EMAIL_ADDRESS%-*}
    echo "    Using $SANITIZED_EMAIL_ADDRESS as recipient…"

    RECIPIENTS_ARG="$RECIPIENTS_ARG --recipient $SANITIZED_EMAIL_ADDRESS"
  done

  echo "  Encrypting message…"

  # Support expired keys.
  if [[ $SENDER_EMAIL_ADDRESS =~ ^expired ]]; then
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --trust-model=always --faked-system-time=$KEY_EXPIRE_ARG  $RECIPIENTS_ARG --encrypt < "$SIGNED_MESSAGE_DIR/signed-message" >> "$MAIL_DIR/$TEST_MAIL.box"
  else
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --trust-model=always $RECIPIENTS_ARG --encrypt < "$SIGNED_MESSAGE_DIR/signed-message" >> "$MAIL_DIR/$TEST_MAIL.box"
  fi

  echo "  Ending mail file…"
  cat "$MAIL_DIR/$TEST_MAIL.part3.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  # Cleanup.
  rm -rf $SIGNED_MESSAGE_DIR && unset SIGNED_MESSAGE_DIR
done

echo "Generating encrypted + signed test mails (combined)"

# Don't use dashes (-) in email addresses unless you know what you're doing!
# shellcheck disable=SC2042
for TEST_MAIL_SENDER_RECIPIENTS in mail-combined,pgp1@example.com,pgp2@example.com,pgp3@example.com
do
  TEST_MAIL=${TEST_MAIL_SENDER_RECIPIENTS%,*,*,*}
  EMAIL_ADDRESSES=${TEST_MAIL_SENDER_RECIPIENTS#*,}
  SENDER_EMAIL_ADDRESS=${EMAIL_ADDRESSES%,*,*}
  # shellcheck disable=SC2206
  RECIPIENTS=(${EMAIL_ADDRESSES#*,})
  # shellcheck disable=SC2128
  IFS=',' read -r -a RECIPIENT_EMAIL_ADDRESSES <<< "$RECIPIENTS"

  echo "Processing mail: $TEST_MAIL"

  KEY_INFO=$(gpg --batch --quiet --with-colons --with-fingerprint --fixed-list-mode --show-key "$KEY_DIR/$SENDER_EMAIL_ADDRESS.pub.asc")
  KEY_FINGERPRINT=$(echo "$KEY_INFO" | head -n 2 | tail -1 | cut -d: -f10)

  KEY_EXPIRES_AT=$(echo "$KEY_INFO" | head -n 1 | cut -d: -f7)
  KEY_EXPIRATION_DATE=$(date -d @$KEY_EXPIRES_AT -R 2>/dev/null || date -r $KEY_EXPIRES_AT -R)
  KEY_EXPIRE_ARG=$(date -d @$KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S' 2>/dev/null || date -r $KEY_EXPIRES_AT -u +'%Y%m%dT%H%M%S')

  echo "  Importing key for $SENDER_EMAIL_ADDRESS"
  gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$SENDER_EMAIL_ADDRESS.asc"

  echo "  Computing current date header…"
  echo "Date: $(date -R)" > "$MAIL_DIR/$TEST_MAIL.box"

  # Support expired keys.
  [[ $SENDER_EMAIL_ADDRESS =~ ^expired ]] && echo "Date: $KEY_EXPIRATION_DATE" > "$MAIL_DIR/$TEST_MAIL.box"

  echo "  Constructing mail body…"
  cat "$MAIL_DIR/$TEST_MAIL.part1.box" >> "$MAIL_DIR/$TEST_MAIL.box"

  for RECIPIENT_EMAIL_ADDRESS in "${RECIPIENT_EMAIL_ADDRESSES[@]}"
  do
    echo "  Importing public key for $RECIPIENT_EMAIL_ADDRESS"
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --yes --import < "$KEY_DIR/$RECIPIENT_EMAIL_ADDRESS.pub.asc"

    SANITIZED_EMAIL_ADDRESS=${RECIPIENT_EMAIL_ADDRESS%-*}
    echo "    Using $SANITIZED_EMAIL_ADDRESS as recipient…"

    RECIPIENTS_ARG="$RECIPIENTS_ARG --recipient $SANITIZED_EMAIL_ADDRESS"
  done

  echo "  Encrypting + signing message in one command…"

  # Support expired keys.
  if [[ $SENDER_EMAIL_ADDRESS =~ ^expired ]]; then
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --trust-model=always --faked-system-time=$KEY_EXPIRE_ARG --default-key $KEY_FINGERPRINT --sign $RECIPIENTS_ARG --encrypt < "$MAIL_DIR/$TEST_MAIL.part2.box" >> "$MAIL_DIR/$TEST_MAIL.box"
  else
    gpg --batch --quiet --pinentry=loopback --passphrase=$KEY_PASSPHRASE --armor --trust-model=always --default-key $KEY_FINGERPRINT --sign $RECIPIENTS_ARG --encrypt < "$MAIL_DIR/$TEST_MAIL.part2.box" >> "$MAIL_DIR/$TEST_MAIL.box"
  fi

  echo "  Ending mail file…"
  cat "$MAIL_DIR/$TEST_MAIL.part3.box" >> "$MAIL_DIR/$TEST_MAIL.box"
done

echo "Done."
