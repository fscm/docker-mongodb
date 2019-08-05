FROM fscm/debian:buster as build

ARG BUSYBOX_VERSION="1.31.0"
ARG MONGODB_VERSION="4.0.11"

ENV \
  LANG=C.UTF-8 \
  DEBIAN_FRONTEND=noninteractive

COPY files/ /root/

WORKDIR /root

RUN \
  apt-get -qq update && \
  apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    curl \
    gzip \
    libc6 \
    libcurl4 \
    libgcc1 \
    libpcap0.8 \
    libssl1.1 \
    tar && \
  mkdir -p /build/data/mongodb && \
  [ -L /usr/lib/x86_64-linux-gnu/libpcap.so.1 ] || ln -s $(basename /usr/lib/x86_64-linux-gnu/libpcap.so.1.*) /usr/lib/x86_64-linux-gnu/libpcap.so.1 && \
  curl -sL --retry 3 --insecure "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VERSION}.tgz" | tar xz --no-same-owner --strip-components=1 -C /build/ --wildcards mongodb-*/bin && \
  rm -rf /build/bin/install_compass && \
  mkdir -p /build/run/systemd && \
  echo 'docker' > /build/run/systemd/container && \
  curl -sL --retry 3 --insecure "https://raw.githubusercontent.com/fscm/tools/master/lddcp/lddcp" -o ./lddcp && \
  chmod +x ./lddcp && \
  ./lddcp $(for f in `find /build/ -type f -executable`; do echo "-p $f "; done) $(for f in `find /lib/x86_64-linux-gnu/ \( -name 'libnss*' -o -name 'libresolv*' \)`; do echo "-l $f "; done) -d /build && \
  curl -sL --retry 3 --insecure "https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-i686-uclibc/busybox" -o /build/bin/busybox && \
  chmod +x /build/bin/busybox && \
  for p in [ [[ basename cat cp date dirname du env getopt grep gzip id kill less ln ls mkdir pgrep ps pwd rm sed sh tar wget; do ln /build/bin/busybox /build/bin/${p}; done && \
  mkdir -p /build/usr/local && \
  chmod a+x /root/tests/* && \
  cp -R /root/tests /build/usr/local/ && \
  chmod a+x /root/scripts/* && \
  cp /root/scripts/* /build/bin/



FROM scratch

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>"

EXPOSE 27017

COPY --from=build \
  /build .

VOLUME ["/data/mongodb"]

ENV LANG=C.UTF-8

ENTRYPOINT ["/bin/run"]

CMD ["help"]
