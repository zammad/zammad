FROM debian:buster

ENV CERT_DIR "/etc/ssl/certs"

# install openssl
RUN apt-get --quiet update
RUN apt-get --quiet --yes install openssl libfaketime

# move base files to the container
COPY config/* /
COPY docker-entrypoint.sh /

# enable volume to generate certificates into the hosts FS
VOLUME ["$CERT_DIR"]

# preload faketime library
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1

# start
ENTRYPOINT ["/docker-entrypoint.sh"]
