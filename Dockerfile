FROM fscm/debian:buster as build

ARG BUSYBOX_VERSION="1.31.0"
ARG MONGODB_VERSION="4.2.1"

ENV \
  LANG=C.UTF-8 \
  DEBIAN_FRONTEND=noninteractive

COPY files/ /root/

WORKDIR /root

RUN \
# dependencies
  apt-get -qq update && \
  apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    ca-certificates \
    curl \
    gzip \
    libc6 \
    libcurl4 \
    libgcc1 \
    libpcap0.8 \
    libssl1.1 \
    tar \
    > /dev/null 2>&1 && \
# build structure
  for folder in bin lib lib64; do install --directory --owner=root --group=root --mode=0755 /build/usr/${folder}; ln -s usr/${folder} /build/${folder}; done && \
  for folder in tmp data; do install --directory --owner=root --group=root --mode=1777 /build/${folder}; done && \
# copy tests
  #install --directory --owner=root --group=root --mode=0755 /build/usr/bin && \
  install --owner=root --group=root --mode=0755 --target-directory=/build/usr/bin /root/tests/* && \
# copy scripts
  install --owner=root --group=root --mode=0755 --target-directory=/build/usr/bin /root/scripts/* && \
# busybox
  curl --silent --location --retry 3 "https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-i686-uclibc/busybox" \
    -o /build/usr/bin/busybox && \
  chmod +x /build/usr/bin/busybox && \
  for p in [ basename cat chmod cp date dirname du env getopt grep gzip id kill less ln ls mkdir pgrep printf ps pwd rm sed sh tar wget; do ln /build/usr/bin/busybox /build/usr/bin/${p}; done && \
# mongodb
  #[ -L /usr/lib/x86_64-linux-gnu/libpcap.so.1 ] || ln -s $(basename /usr/lib/x86_64-linux-gnu/libpcap.so.1.*) /usr/lib/x86_64-linux-gnu/libpcap.so.1 && \
  curl --silent --location --retry 3 "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-${MONGODB_VERSION}.tgz" \
    | tar xz --no-same-owner --strip-components=1 -C /build/ --wildcards mongodb-*/bin && \
  rm -rf /build/bin/install_compass && \
# system settings
  install --directory --owner=root --group=root --mode=0755 /build/run/systemd && \
  echo 'docker' > /build/run/systemd/container && \
# lddcp
  curl --silent --location --retry 3 "https://raw.githubusercontent.com/fscm/tools/master/lddcp/lddcp" \
    -o ./lddcp && \
  chmod +x ./lddcp && \
  ./lddcp $(for f in `find /build/ -type f -executable`; do echo "-p $f "; done) $(for f in `find /lib/x86_64-linux-gnu/ \( -name 'libnss*' -o -name 'libresolv*' \)`; do echo "-l $f "; done) -d /build



FROM scratch

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>"

EXPOSE 27017

COPY --from=build \
  /build .

VOLUME ["/data"]

WORKDIR /data

ENV LANG=C.UTF-8

ENTRYPOINT ["/usr/bin/run"]

CMD ["help"]
