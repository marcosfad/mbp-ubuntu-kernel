#!/bin/bash

set -eu -o pipefail

## Update docker image tag, because kernel build is using `uname -r` when defining package version variable
# KERNEL_VERSION=$(curl -s https://www.kernel.org | grep '<strong>' | head -3 | tail -1 | cut -d'>' -f3 | cut -d'<' -f1)
KERNEL_VERSION=5.6.5
REPO_PATH=$(pwd)
WORKING_PATH=/root/work
KERNEL_PATH="${WORKING_PATH}/linux-kernel"
GIT_USERNAME="Ubuntu MBP"
GIT_EMAIL="turkos+ubuntu-mbp@gmail.com"

### Debug commands
echo "KERNEL_VERSION=$KERNEL_VERSION"
echo "${WORKING_PATH}"
echo "Current path: ${REPO_PATH}"
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

### Clean up
rm -rfv ./*.deb

mkdir "${WORKING_PATH}" && cd "${WORKING_PATH}"
cp -rf "${REPO_PATH}"/{patches,templates} "${WORKING_PATH}"
rm -rf linux-*

### Dependencies
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y build-essential fakeroot libncurses-dev bison flex libssl-dev libelf-dev \
  openssl dkms libudev-dev libpci-dev libiberty-dev autoconf wget xz-utils git \
  bc rsync cpio dh-modaliases debhelper kernel-wedge

### get Kernel
git clone --depth 1 --single-branch --branch v"${KERNEL_VERSION}" \
  git://kernel.ubuntu.com/virgin/linux-stable.git "${KERNEL_PATH}"
cd ./linux-kernel || exit
git config user.name "${GIT_USERNAME}"
git config user.email "${GIT_EMAIL}"

#### Create patch file with custom drivers
echo >&2 "===]> Info: Creating patch file... "
KERNEL_VERSION="${KERNEL_VERSION}" WORKING_PATH="${WORKING_PATH}" "${REPO_PATH}/patch_driver.sh"

#### Apply patches
cd "${KERNEL_PATH}" || exit

echo >&2 "===]> Info: Applying patches... "
[ ! -d "${WORKING_PATH}/patches" ] && {
  echo 'Patches directory not found!'
  exit 1
}
while IFS= read -r file; do
  echo "adding $file"
  patch -p1 <"$file"
done < <(find "${WORKING_PATH}/patches" -type f -name "*.patch" | sort)

### Add new drivers. This config files comes on the one of the patches...
echo "CONFIG_APPLE_BCE_DRIVER=m" >>"${KERNEL_PATH}/debian.master/config/amd64/config.common.ubuntu"
echo "CONFIG_APPLE_TOUCHBAR_DRIVER=m" >>"${KERNEL_PATH}/debian.master/config/amd64/config.common.ubuntu"
find "${KERNEL_PATH}/debian.master/config/" -type f -name "generic.modules" -exec sh -c '
  echo -e "apple-bce.ko\napple-ib-als.ko\napple-ib-tb.ko\napple-ibridge.ko" >> $1
' sh {} \;

chmod a+x "${KERNEL_PATH}"/debian/rules
chmod a+x "${KERNEL_PATH}"/debian/scripts/*
chmod a+x "${KERNEL_PATH}"/debian/scripts/misc/*

# Get rid of the dirty tag

### Copy configuration
fakeroot debian/rules clean
yes '' | fakeroot /bin/bash -c "export DROOT=debian; export ARCH=amd64; \
 ${KERNEL_PATH}/debian/scripts/misc/kernelconfig updateconfigs amd64" || true

cp "${KERNEL_PATH}/debian.master/config/amd64/config.flavour.generic" ".config"

make olddefconfig

#### Change buildid to mbp
echo >&2 "===]> Info: Bulding src... "
make clean
cd "${KERNEL_PATH}"
git add .
git commit -s -a -m "getting rid of -dirty"
make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-mbp

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... "
#cp -rfv ../*.deb "${REPO_PATH}/"
cp -rfv ../*.deb /tmp/artifacts/
sha256sum ../*.deb >/tmp/artifacts/sha256
