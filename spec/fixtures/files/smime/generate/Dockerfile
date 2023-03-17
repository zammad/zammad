FROM debian:buster as builder
# See https://brendonmatheson.com/2020/08/27/manipulating-time-inside-a-docker-container.html

RUN apt-get update && apt-get install -y make gcc git

# Get the sources and checkout at stable release 0.98
# see https://github.com/wolfcw/libfaketime/releases
RUN git clone https://github.com/wolfcw/libfaketime.git && \
    cd libfaketime && \
    git checkout dc2ae5eef31c7a64ce3a976487d8e57d50b8d594 && \
    make

FROM debian:buster as final

COPY --from=builder /libfaketime/src/libfaketime.so.1 /usr/local/lib
ENV LD_PRELOAD=/usr/local/lib/libfaketime.so.1

ENV CERT_DIR "/etc/ssl/certs"

# install openssl
RUN apt-get update
RUN apt-get -q -y install openssl

# move base files to the container
COPY config/* /
COPY docker-entrypoint.sh /

# enable volume to generate certificates into the hosts FS
VOLUME ["$CERT_DIR"]

# start
ENTRYPOINT ["/docker-entrypoint.sh"]
