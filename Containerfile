FROM localhost/postmarketos:latest AS builder

COPY vmlinuz-stable /boot/vmlinuz

RUN apk add --no-cache \
  dracut \
  git \
  meson \
  fuse3-dev \
  linux-headers \
  clang \
  pkgconfig \
  make \
  autoconf \
  cmake \
  valgrind \
  go-md2man \
  libc++-dev \
  libcap-dev \
  linux-firmware \
  ostree \
  ostree-dev \
  btrfs-progs \
  e2fsprogs \
  xfsprogs \
  udev \
  cpio \
  zstd \
  binutils \
  dosfstools \
  conmon \
  crun \
  netavark \
  skopeo \
  dbus \
  dbus-glib \
  glib \
  u-boot \
  u-boot-tools \
  rust \
  cargo \
  shadow \
  systemd-boot \
  musl-fts \
  nvme-cli \
  jq \
  openssh \
  open-lldp \
  lvm2 \
  mdadm \
  ntfs-3g \
  curl \
  keyutils \
  libcap-utils \
  dash \
  dmraid \
  cifs-utils \
  open-iscsi \
  rpcbind \
  nfs-utils


RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/composefs/composefs composefs && \
    cd composefs && \
    git fetch --all && \
    CC=clang CXX=clang++ meson build && \
    cd build \
    meson compile \
    meson install

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/bootc-dev/bootc.git bootc && \
    cd bootc && \
    git fetch --all && \
    git switch origin/composefs-backend -d && \
    sed -i 's/use-libc/use-libc-auxv/g' Cargo.toml && \
    CC=clang CXX=clang++ make && \
    make install

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/p5/coreos-bootupd.git bootupd && \
    cd bootupd && \
    git fetch --all && \
    git switch origin/sdboot-support -d && \
    CC=clang CXX=clang++ cargo build --release --bins --features systemd-boot && \
    make install

RUN env \
    KERNEL_VERSION="$(basename "$(find "/lib/modules" -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" \
    sh -c 'dracut --force --no-hostonly --reproducible --zstd --verbose --kver "${KERNEL_VERSION}" "/lib/modules/${KERNEL_VERSION}/initramfs.img"'

RUN mkdir -p boot sysroot var/home && \
    rm -rf var/log home root usr/local srv && \
    ln -s /var/home home && \
    ln -s /var/roothome root && \
    ln -s /var/usrlocal usr/local && \
    ln -s /var/srv srv

# Update useradd default to /var/home instead of /home for User Creation
RUN mkdir /etc/default
RUN echo "HOME=/var/home" > "/etc/default/useradd"

# Setup a temporary root passwd (changeme) for dev purposes
# TODO: Replace this for a more robust option when in prod
RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

# Necessary for `bootc install`
RUN echo -e '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true' | tee "/usr/lib/ostree/prepare-root.conf"


COPY ./initramfs /boot/initramfs
RUN KERNEL_VERSION="$(basename "$(find "/lib/modules" -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" cp /boot/vmlinuz /usr/lib/modules/${KERNEL_VERSION}/vmlinuz
RUN KERNEL_VERSION="$(basename "$(find "/lib/modules" -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" cp /boot/initramfs /usr/lib/modules/${KERNEL_VERSION}/initramfs
LABEL containers.bootc 1
