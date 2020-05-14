#!/bin/bash

set -eu -o pipefail

## Update docker image tag, because kernel build is using `uname -r` when defining package version variable
# KERNEL_VERSION=$(curl -s https://www.kernel.org | grep '<strong>' | head -3 | tail -1 | cut -d'>' -f3 | cut -d'<' -f1)
KERNEL_VERSION=5.6.13
#KERNEL_REPOSITORY=git://kernel.ubuntu.com/virgin/linux-stable.git
KERNEL_REPOSITORY=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
REPO_PATH=$(pwd)
WORKING_PATH=/root/work
KERNEL_PATH="${WORKING_PATH}/linux-kernel"

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
  bc rsync cpio dh-modaliases debhelper kernel-wedge curl

### get Kernel
git clone --depth 1 --single-branch --branch "v${KERNEL_VERSION}" \
  "${KERNEL_REPOSITORY}" "${KERNEL_PATH}"
cd ./linux-kernel || exit

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

#echo >&2 "===]> Info: Add drivers default configuration... "
### Add new drivers. This config files comes on the one of the patches...
#echo "CONFIG_APPLE_BCE_DRIVER=m" >>"${KERNEL_PATH}/debian.master/config/amd64/config.common.ubuntu"
#echo "CONFIG_APPLE_TOUCHBAR_DRIVER=m" >>"${KERNEL_PATH}/debian.master/config/amd64/config.common.ubuntu"
#find "${KERNEL_PATH}/debian.master/config/" -type f -name "generic.modules" -exec sh -c '
#  echo -e "apple-bce.ko\napple-ib-als.ko\napple-ib-tb.ko\napple-ibridge.ko" >> $1
#' sh {} \;

chmod a+x "${KERNEL_PATH}"/debian/rules
chmod a+x "${KERNEL_PATH}"/debian/scripts/*
chmod a+x "${KERNEL_PATH}"/debian/scripts/misc/*

echo >&2 "===]> Info: Bulding src... "

cd "${KERNEL_PATH}"
make clean
cp "${WORKING_PATH}/templates/default-config" .config
make olddefconfig

# Get rid of the dirty tag
#LASTEST_BUILD=$(curl -s https://mbp-ubuntu-kernel.herokuapp.com/ -L |
#  grep linux-image-${KERNEL_VERSION} | grep a | cut -d'>' -f2 | cut -d'<' -f1 |
#  sort -r | head -n 1 | cut -d'-' -f6 | cut -d'_' -f1)
#NEXT_BUILD=$(expr ${LASTEST_BUILD} + 1)
echo "" >${KERNEL_PATH}/.scmversion

make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-mbp

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... "
#cp -rfv ../*.deb "${REPO_PATH}/"
#cp -rfv "${KERNEL_PATH}/.config" "${REPO_PATH}/kernel_config"
cp -rfv ../*.deb /tmp/artifacts/
sha256sum ../*.deb >/tmp/artifacts/sha256
