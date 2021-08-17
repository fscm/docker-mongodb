# global args
ARG __BUILD_DIR__="/build"
ARG __DATA_DIR__="/data"



FROM fscm/debian:buster as build

ARG __BUILD_DIR__
ARG __DATA_DIR__
ARG MONGODB_VERSION="5.0.2"
ARG __USER__="root"
ARG __WORK_DIR__="/work"

ENV \
  LANG="C.UTF-8" \
  LC_ALL="C.UTF-8" \
  DEBCONF_NONINTERACTIVE_SEEN="true" \
  DEBIAN_FRONTEND="noninteractive"

USER ${__USER__}

COPY "LICENSE" "files/" "${__WORK_DIR__}"/
COPY --from=busybox:uclibc "/bin/busybox" "${__WORK_DIR__}"/

WORKDIR "${__WORK_DIR__}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
# build env
  echo '--> setting build env' && \
  set +h && \
# build structure
  echo '--> creating build structure' && \
  for folder in bin lib lib64 sbin; do \
    install --directory --owner="${__USER__}" --group="${__USER__}" --mode=0755 "${__BUILD_DIR__}/usr/${folder}"; \
    ln --symbolic "usr/${folder}" "${__BUILD_DIR__}/${folder}"; \
  done && \
  for folder in tmp ${__DATA_DIR__}; do \
    install --directory --owner="${__USER__}" --group="${__USER__}" --mode=1777 "${__BUILD_DIR__}/${folder}"; \
  done && \
# dependencies
  echo '--> instaling dependencies' && \
  apt-get -qq update && \
  apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    ca-certificates \
    binutils \
    bzip2 \
    curl \
    gzip \
    libc6 \
    libcurl4 \
    libgcc1 \
    libpcap0.8 \
    libssl1.1 \
    tar \
    > /dev/null 2>&1 && \
# copy tests
  echo '--> copying test files' && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" "${__WORK_DIR__}/tests"/* && \
# copy scripts
  echo '--> copying scripts' && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" "${__WORK_DIR__}/scripts"/* && \
# mongodb
  echo '--> installing mongodb' && \
  install --directory "${__WORK_DIR__}/mongodb" && \
  curl --silent --location --retry 3 "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian10-${MONGODB_VERSION}.tgz" \
    | tar xz --no-same-owner --strip-components=1 -C "${__WORK_DIR__}/mongodb" --exclude='*/install_compass' && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" "${__WORK_DIR__}/mongodb/bin"/* && \
  install --directory --owner="${__USER__}" --group="${__USER__}" --mode=0755 "${__BUILD_DIR__}/licenses/mongodb" && \
  (cd "${__WORK_DIR__}/mongodb" && find ./ -type f -a \( -name '*LICENSE*' -o -name '*COPYING*' -o -name '*NOTICES*' -o -name '*MPL-*' \) -exec cp --parents {} "${__BUILD_DIR__}/licenses/mongodb" ';') && \
# busybox
  echo '--> installing busybox' && \
  install --owner="${__USER__}" --group="${__USER__}" --mode=0755 --target-directory="${__BUILD_DIR__}/usr/bin" "${__WORK_DIR__}/busybox" && \
  install --directory --owner="${__USER__}" --group="${__USER__}" --mode=0755 "${__BUILD_DIR__}/licenses/busybox" && \
  curl --silent --location --retry 3 "https://git.busybox.net/busybox/plain/LICENSE" --output "${__BUILD_DIR__}/licenses/busybox/LICENSE" && \
  for p in [ basename chmod dirname getopt gzip id kill mkdir pgrep printf pwd sed sh tar wget; do \
    p_path="$(${__WORK_DIR__}/busybox --list-full | sed 's/$/ /' | grep -F "/${p} "  | sed -e '/^usr/! s|^|usr/|' -e 's/ $//')"; \
    ln "${__BUILD_DIR__}/usr/bin/busybox" "${__BUILD_DIR__}/${p_path}"; \
  done && \
# lddcp
  echo '--> copying required libs' && \
  curl --silent --location --retry 3 --output "${__WORK_DIR__}/lddcp" "https://raw.githubusercontent.com/fscm/tools/master/lddcp/lddcp" && \
  chmod +x "${__WORK_DIR__}/lddcp" && \
  "${__WORK_DIR__}"/lddcp $(for f in `find /build/ -type f -executable`; do echo "-p $f "; done) $(for f in `find /lib/x86_64-linux-gnu/ \( -name 'libnss*' -o -name 'libresolv*' \)`; do echo "-l $f "; done) -d /build && \
# stripping
  echo '--> stripping libraries and binaries' && \
  find "${__BUILD_DIR__}/usr/lib" "${__BUILD_DIR__}/usr/lib64" -type f -name '*.so*' -exec strip --strip-unneeded {} ';' && \
  find "${__BUILD_DIR__}/usr/bin" -type f -not -links +1 -exec strip --strip-all {} ';' && \
# licenses
  echo '--> project licenses' && \
  install --owner=${__USER__} --group=${__USER__} --mode=0644 --target-directory="${__BUILD_DIR__}/licenses" "${__WORK_DIR__}/LICENSE" && \
# done
  echo '--> all done!'



FROM scratch

ARG __BUILD_DIR__
ARG __DATA_DIR__

LABEL \
  maintainer="Frederico Martins <https://hub.docker.com/u/fscm/>" \
  vendor="fscm" \
  cmd="docker container run --detach --publish 27017:27017/tcp fscm/mongodb start" \
  params="--volume ./:${__DATA_DIR__}:rw "

EXPOSE 27017/tcp

COPY --from=build "${__BUILD_DIR__}" "/"

VOLUME ["${__DATA_DIR__}"]

WORKDIR "${__DATA_DIR__}"

ENV \
  DATA_DIR="${__DATA_DIR__}"

ENTRYPOINT ["/usr/bin/entrypoint"]

CMD ["help"]
