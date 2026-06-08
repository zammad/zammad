#!/bin/sh
set -eu

# Configurable settings with defaults

LDAP_BASE_DN="${LDAP_BASE_DN:-dc=foo,dc=example,dc=com}"
LDAP_ADMIN_DN="${LDAP_ADMIN_DN:-cn=admin,${LDAP_BASE_DN}}"
LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-test}"
LDAP_DISALLOW_BIND_ANON="${LDAP_DISALLOW_BIND_ANON:-false}"

# Unconfigurable settings
LDAP_PORT=389
LDAP_LDAPS_PORT=636
LDAP_TLS_CERT_FILE="/certs/ldap.crt"
LDAP_TLS_KEY_FILE="/certs/ldap.key"
LDAP_TLS_CA_FILE="/certs/ca.crt"

DATA_DIR="/var/lib/openldap/openldap-data"
SLAPD_CONF="/etc/openldap/slapd.conf"
INIT_FLAG="${DATA_DIR}/.initialized"

# Generate TLS certificates if they don't already exist (e.g. first start or fresh volume).
if [ ! -f "${LDAP_TLS_KEY_FILE}" ]; then
    echo "==> Generating self-signed TLS certificates..."

    CERTS_DIR="$(dirname "${LDAP_TLS_CERT_FILE}")"
    mkdir -p "${CERTS_DIR}"

    # CA key + self-signed CA certificate
    openssl genrsa -out /tmp/ca.key 4096 2>/dev/null
    openssl req -new -x509 -days 3650 \
        -key /tmp/ca.key \
        -out "${LDAP_TLS_CA_FILE}" \
        -subj "/CN=Zammad Dev LDAP CA/O=Zammad Dev" 2>/dev/null

    # Server key + CSR
    openssl genrsa -out "${LDAP_TLS_KEY_FILE}" 2048 2>/dev/null
    openssl req -new \
        -key "${LDAP_TLS_KEY_FILE}" \
        -out /tmp/ldap.csr \
        -subj "/CN=ldap/O=Zammad Dev" 2>/dev/null

    # SAN extension so Ruby's OpenSSL accepts the certificate
    printf 'subjectAltName=DNS:ldap,DNS:localhost,IP:127.0.0.1\n' > /tmp/ldap.ext

    # Sign server certificate with CA
    openssl x509 -req -days 3650 \
        -in /tmp/ldap.csr \
        -CA "${LDAP_TLS_CA_FILE}" \
        -CAkey /tmp/ca.key \
        -set_serial 1 \
        -out "${LDAP_TLS_CERT_FILE}" \
        -extfile /tmp/ldap.ext 2>/dev/null

    chown ldap:ldap "${LDAP_TLS_KEY_FILE}" "${LDAP_TLS_CERT_FILE}" "${LDAP_TLS_CA_FILE}"
    rm -f /tmp/ca.key /tmp/ldap.csr /tmp/ldap.ext

    echo "==> TLS certificates generated."
fi

# Regenerate slapd.conf on every startup so env-var changes are picked up.
HASHED_PASS=$(slappasswd -s "${LDAP_ADMIN_PASSWORD}")
DISALLOW_DIRECTIVE=""
[ "${LDAP_DISALLOW_BIND_ANON}" = "true" ] && DISALLOW_DIRECTIVE="disallow bind_anon"

cat > "${SLAPD_CONF}" <<EOF
include /etc/openldap/schema/core.schema
include /etc/openldap/schema/cosine.schema
include /etc/openldap/schema/inetorgperson.schema
include /etc/openldap/schema/nis.schema

modulepath /usr/lib/openldap
moduleload back_mdb

pidfile  /tmp/slapd.pid
argsfile /tmp/slapd.args

TLSCertificateFile    ${LDAP_TLS_CERT_FILE}
TLSCertificateKeyFile ${LDAP_TLS_KEY_FILE}
TLSCACertificateFile  ${LDAP_TLS_CA_FILE}

${DISALLOW_DIRECTIVE}

database mdb
suffix   "${LDAP_BASE_DN}"
rootdn   "${LDAP_ADMIN_DN}"
rootpw   ${HASHED_PASS}
directory ${DATA_DIR}
maxsize   1073741824

access to attrs=userPassword
  by dn.base="${LDAP_ADMIN_DN}" manage
  by anonymous auth
  by * none

access to *
  by dn.base="${LDAP_ADMIN_DN}" manage
  by users read
  by * none
EOF

if [ ! -f "${INIT_FLAG}" ]; then
    echo "==> First-time initialization..."

    for ldif in /ldifs/*.ldif; do
        basename=$(basename "${ldif}")
        # Skip cn=config LDIF files — their settings are handled via slapd.conf above.
        if ! grep -q "^dn: cn=config" "${ldif}" 2>/dev/null; then
            echo "  -> data: ${basename}"
            slapadd -f "${SLAPD_CONF}" -l "${ldif}"
        fi
    done

    chown -R ldap:ldap "${DATA_DIR}"
    touch "${INIT_FLAG}"
    echo "==> Initialization complete."
fi

echo "==> Starting slapd on ldap://0.0.0.0:${LDAP_PORT} and ldaps://0.0.0.0:${LDAP_LDAPS_PORT}..."
exec /usr/sbin/slapd \
    -h "ldap://0.0.0.0:${LDAP_PORT}/ ldaps://0.0.0.0:${LDAP_LDAPS_PORT}/" \
    -u ldap \
    -g ldap \
    -f "${SLAPD_CONF}" \
    -d 256
