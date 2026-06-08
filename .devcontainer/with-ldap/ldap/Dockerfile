FROM alpine:3

RUN apk add --no-cache \
    openldap \
    openldap-back-mdb \
    openldap-clients \
    openssl

ENV LDAP_BASE_DN="dc=foo,dc=example,dc=com"
# LDAP_ADMIN_PASSWORD defaults to "test" in the entrypoint — override at runtime
ENV LDAP_PORT="389"
ENV LDAP_LDAPS_PORT="636"

COPY docker-entrypoint.sh /usr/local/bin/
COPY bootstrap/ldif/ /ldifs/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /var/lib/openldap/openldap-data \
    && chown -R ldap:ldap /ldifs /var/lib/openldap

EXPOSE 389 636

ENTRYPOINT ["docker-entrypoint.sh"]
