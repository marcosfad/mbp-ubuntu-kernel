#!/bin/bash

set -eu -o pipefail

## Update docker image tag, because kernel build is using `uname -r` when defining package version variable
KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v5.x
KERNEL_VERSION=5.6.4

### Debug commands
echo "KERNEL_VERSION=$KERNEL_VERSION"
pwd
ls
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

## Cleanup
rm -rfv ./*.deb
rm -rf linux-$KERNEL_VERSION*

### Dependencies
apt update
apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev \
  openssl dkms libudev-dev libpci-dev libiberty-dev autoconf wget xz-utils git \
  bc rsync cpio

### get Kernel and signature
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 647F28654894E3BD457199BE38DBBDC86092693E # Linus Torvalds
wget $KERNEL_URL/linux-$KERNEL_VERSION.tar.xz
wget $KERNEL_URL/linux-$KERNEL_VERSION.tar.sign
xz -d linux-$KERNEL_VERSION.tar.xz
gpg --verify linux-$KERNEL_VERSION.tar.sign

tar xf linux-$KERNEL_VERSION.tar
rm linux-$KERNEL_VERSION.tar

cd linux-$KERNEL_VERSION

#### Create patch file with custom drivers
echo >&2 "===]> Info: Creating patch file... ";
KERNEL_VERSION=${KERNEL_VERSION} ../patch_driver.sh

#### Apply patches
echo >&2 "===]> Info: Applying patches... ";
[ ! -d ../patches ] && { echo 'Patches directory not found!'; exit 1; }
while IFS= read -r file
do
  echo "adding $file"
  patch -p1 < "$file"
done < <(find ../patches -type f -name "*.patch" | sort)

#### Change buildid to mbp
echo >&2 "===]> Info: Bulding src... ";
cp ../template/default-config .config

make olddefconfig
make clean
make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-mbp

#### Build src rpm
#echo >&2 "===]> Info: Install kernel ... ";
#make modules_install -j "$(getconf _NPROCESSORS_ONLN)"
#make install -j `getconf _NPROCESSORS_ONLN`

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... ";
cp -rfv ../*.deb /tmp/artifacts/
sha256sum ../*.deb > /tmp/artifacts/sha256

