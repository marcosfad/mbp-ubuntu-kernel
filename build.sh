#!/bin/bash

set -eu -o pipefail

KERNEL_VERSION=5.13.3
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

get_next_version () {
  "${REPO_PATH}"/next_version.sh "${1}"
}

### Clean up
rm -rfv ./*.deb

mkdir "${WORKING_PATH}" && cd "${WORKING_PATH}"
cp -rf "${REPO_PATH}"/{patches,templates} "${WORKING_PATH}"
rm -rf "${KERNEL_PATH}"

### Dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential fakeroot libncurses-dev bison flex libssl-dev libelf-dev \
  openssl dkms libudev-dev libpci-dev libiberty-dev autoconf wget xz-utils git \
  bc rsync cpio dh-modaliases debhelper kernel-wedge curl

### get Kernel
git clone --depth 1 --single-branch --branch "v${KERNEL_VERSION}" \
  "${KERNEL_REPOSITORY}" "${KERNEL_PATH}"
cd "${KERNEL_PATH}" || exit

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
  echo "==> Adding $file"
  patch -p1 <"$file"
done < <(find "${WORKING_PATH}/patches" -type f -name "*.patch" | sort)

chmod a+x "${KERNEL_PATH}"/debian/rules
chmod a+x "${KERNEL_PATH}"/debian/scripts/*
chmod a+x "${KERNEL_PATH}"/debian/scripts/misc/*

echo >&2 "===]> Info: Bulding src... "

cd "${KERNEL_PATH}"
make clean
cp "${WORKING_PATH}/templates/default-config" "${KERNEL_PATH}/.config"
make olddefconfig

# Get rid of the dirty tag
echo "" >"${KERNEL_PATH}"/.scmversion

# Build Deb packages
#make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-mbp KDEB_PKGVERSION="$(make kernelversion)-$(get_next_version mbp)"

# build alternate kernel with corellium's wifi patches, for MBP16,1/2/4 and MBA9,1
echo >&2 "===]> Info: Create alternative kernel with corellium wifi patch... "
#make distclean
#make clean
# reverse other wifi patches
#while IFS= read -r file; do
#  echo "==> Reverting $file"
#  patch -R -p1 <"$file"
#done < <(find "${WORKING_PATH}/patches" -type f -name "*.patch" | grep "brcmfmac" | sort -r)

#echo "==> Adding wifi-bigsur.patch"
#curl https://raw.githubusercontent.com/jamlam/mbp-16.1-linux-wifi/4c8b393ed7a874e3d9e44a2a467c1b7c74af1260/wifi-bigsur.patch \
#| patch -p1
#cp "${WORKING_PATH}/templates/default-config" "${KERNEL_PATH}/.config"
#make olddefconfig
#echo "" >"${KERNEL_PATH}"/.scmversion

make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-mbp-16x-wifi KDEB_PKGVERSION="${KERNEL_VERSION}-$(get_next_version mbp)"

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... "
cp -rfv "${KERNEL_PATH}/.config" "/tmp/artifacts/kernel_config_${KERNEL_VERSION}"
cp -rfv ../*.deb /tmp/artifacts/
sha256sum ../*.deb >/tmp/artifacts/sha256
