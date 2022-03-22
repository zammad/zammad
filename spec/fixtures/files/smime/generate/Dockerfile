FROM alpine

# faketime dependencies to generate outdated certificates
# see: https://github.com/trajano/alpine-libfaketime#with-simple-command-line-apps
COPY --from=trajano/alpine-libfaketime  /faketime.so /lib/faketime.so
ENV LD_PRELOAD=/lib/faketime.so
ENV CERT_DIR "/etc/ssl/certs"

# install openssl
RUN apk add --update openssl && \
    rm -rf /var/cache/apk/*

# move base files to the container
COPY config/* /
COPY docker-entrypoint.sh /

# enable volume to generate certificates into the hosts FS
VOLUME ["$CERT_DIR"]

# start
ENTRYPOINT ["/docker-entrypoint.sh"]
