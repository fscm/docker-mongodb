FROM fscm/debian:stretch as build

ARG BUSYBOX_VERSION="1.27.1"
ARG MONGODB_VERSION="4.0.6"

ENV DEBIAN_FRONTEND=noninteractive

COPY files/ /root/

RUN \
  apt-get -qq update && \
  apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install curl libc6 libcurl3 libgcc1 libpcap0.8 libssl1.1 tar && \
  apt-get -qq -y -o=Dpkg::Use-Pty=0 download bash && \
  sed -i '/path-include/d' /etc/dpkg/dpkg.cfg.d/90docker-excludes && \
  mkdir -p /build/data/mongodb && \
  dpkg --unpack --force-all --no-triggers --instdir=/build --path-exclude="/etc*" --path-exclude="/usr/share*" bash_*.deb && \
  ln -s /bin/bash /build/bin/sh && \
  [ -L /usr/lib/x86_64-linux-gnu/libpcap.so.1 ] || ln -s $(basename /usr/lib/x86_64-linux-gnu/libpcap.so.1.*) /usr/lib/x86_64-linux-gnu/libpcap.so.1 && \
  curl -sL --retry 3 --insecure "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VERSION}.tgz" | tar xz --no-same-owner --strip-components=1 -C /build/ --wildcards mongodb-*/bin && \
  rm -rf /build/bin/install_compass && \
  mkdir -p /build/run/systemd && \
  echo 'docker' > /build/run/systemd/container && \
  curl -sL --retry 3 --insecure "https://raw.githubusercontent.com/fscm/tools/master/lddcp/lddcp" -o ./lddcp && \
  chmod +x ./lddcp && \
  ./lddcp $(for f in `find /build/ -type f -executable`; do echo "-p $f "; done) -d /build && \
  curl -sL --retry 3 --insecure "https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-i686/busybox" -o /build/bin/busybox && \
  chmod +x /build/bin/busybox && \
  for p in [ [[ basename cat cp date diff du echo env grep less ls mkdir mknod mktemp more mv ping ps rm sort stty; do ln -s busybox /build/bin/${p}; done && \
  chmod a+x /root/scripts/* && \
  cp /root/scripts/* /build/bin/



FROM scratch

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>"

EXPOSE 27017

COPY --from=build \
  /build .

VOLUME ["/data/mongodb"]

ENTRYPOINT ["/bin/run"]

CMD ["help"]
