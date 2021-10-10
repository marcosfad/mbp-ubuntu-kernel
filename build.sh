#!/bin/bash

set -eu -o pipefail

export LANG=C

START_TIME=$(date +%s)

kernel=5.13.13
kernelRepository=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
kernelBranch=v5.13.13
debianSaucePatches=yes
patchset1Repo=git://github.com/aunali1/linux-mbp-arch.git
patchset1Branch=master
patchset1Commit=9511d5ed2ae0e851dd6a82843daefb2be7d5e212
patchset1Filter='cat'
patchset2Repo=''
patchset2Branch=''
patchset2Commit=''
patchset2Filter='cat'
path=/root/work
releaseSuffix=t2
releasePath=/tmp/artifacts

__die() {
  local rc=$1; shift
  printf 1>&2 '%s\n' "ERROR: $*"; exit "${rc}"
}

args=( "$@" );
for (( i=0; i < $# ; i++ ))
do
  arg=${args[$i]}
  if [[ $arg = --*=* ]]
  then
    key=${arg#--}
    val=${key#*=}; key=${key%%=*}
    case "$key" in
      kernel|kernelRepository|kernelBranch|debianSaucePatches|patchset1Repo|patchset1Branch|patchset1Commit|patchset1Filter|patchset2Repo|patchset2Branch|patchset2Commit|patchset2Filter|path|releaseSuffix|releasePath)
        printf -v "$key" '%s' "$val" ;;
      *) __die 1 "Unknown flag $arg"
    esac
  else __die 1 "Bad arg $arg"
  fi
done

# Kernel
KERNEL_VERSION="${kernel}"
KERNEL_REPOSITORY="${kernelRepository}"
KERNEL_BRANCH="${kernelBranch}"
# Patches
PATCHSET_1_URL="${patchset1Repo}"
PATCHSET_1_BRANCH="${patchset1Branch}"
PATCHSET_1_HASH="${patchset1Commit}"
PATCHSET_1_FILTER=${patchset1Filter}
PATCHSET_2_URL="${patchset2Repo}"
PATCHSET_2_BRANCH="${patchset2Branch}"
PATCHSET_2_HASH="${patchset2Commit}"
PATCHSET_2_FILTER=${patchset2Filter}
# Release
RELEASE_SUFFIX="${releaseSuffix}"
# Environment
WORKING_PATH="${path}"
REPO_PATH=$(pwd)
KERNEL_PATH="${WORKING_PATH}/linux-kernel"
PATCHES_PATH="${WORKING_PATH}/patches"
PATCHSET_1_GIT_PATH="${WORKING_PATH}/patchset1"
PATCHSET_2_GIT_PATH="${WORKING_PATH}/patchset2"
RELEASE_PATH="${releasePath}"

### Debug commands
echo "Building kernel ${KERNEL_VERSION}-${RELEASE_SUFFIX} from ${KERNEL_REPOSITORY}"
echo "Current working path: ${WORKING_PATH}"
echo "Current path: ${REPO_PATH}"
echo "CPU threads: $(nproc --all)"
echo "Patchset:
  ${PATCHSET_1_URL}#${PATCHSET_1_BRANCH}#${PATCHSET_1_HASH} with ${PATCHSET_1_FILTER}"
if [ "$PATCHSET_2_BRANCH" != "" ]; then
  echo "
  ${PATCHSET_2_URL}#${PATCHSET_2_BRANCH}#${PATCHSET_2_HASH} with ${PATCHSET_2_FILTER}
"
fi
grep 'model name' /proc/cpuinfo | uniq

get_next_version() {
  "${REPO_PATH}"/next_version.sh "${1}"
}

### Clean up
rm -rfv ./*.deb
rm -rf "${KERNEL_PATH}"
rm -rf "${PATCHES_PATH}" "${PATCHSET_1_GIT_PATH}" "${PATCHSET_2_GIT_PATH}"
rm -rf "${RELEASE_PATH}"

mkdir -p "${WORKING_PATH}" && cd "${WORKING_PATH}"
mkdir -p "${PATCHES_PATH}"
mkdir -p "${RELEASE_PATH}"
cp -rf "${REPO_PATH}/templates" "${WORKING_PATH}"
if [ "$debianSaucePatches" != "no" ]; then
  cp -rf "${REPO_PATH}/patches" "${PATCHES_PATH}"
fi

#### Dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential fakeroot libncurses-dev bison flex libssl-dev libelf-dev \
  openssl dkms libudev-dev libpci-dev libiberty-dev autoconf wget xz-utils git \
  bc rsync cpio dh-modaliases debhelper kernel-wedge curl

#### get Kernel
echo "git clone --depth 1 --single-branch --branch ${KERNEL_BRANCH} ${KERNEL_REPOSITORY} ${KERNEL_PATH}"
git clone --depth 1 --single-branch --branch "${KERNEL_BRANCH}" \
  "${KERNEL_REPOSITORY}" "${KERNEL_PATH}"
cd "${KERNEL_PATH}" || exit

#### Patches
echo >&2 "===]> Info: Adding Debian sauce patches... "
if [ "$debianSaucePatches" != "no" ]; then
  while IFS= read -r file; do
    echo "==> Adding $file"
    patch -p1 <"$file"
  done < <(find "${PATCHES_PATH}" -type f -name "*.patch" | sort)
fi

### Patchset 1
echo >&2 "===]> Info: Adding patchset 1 ... "
git clone --single-branch --branch ${PATCHSET_1_BRANCH} ${PATCHSET_1_URL} \
  "${PATCHSET_1_GIT_PATH}"
cd "${PATCHSET_1_GIT_PATH}" || exit
git checkout ${PATCHSET_1_HASH}

cd "${KERNEL_PATH}" || exit
while IFS= read -r file; do
  echo "==> Adding ${file}"
  patch -p1 <"$file"
done < <(find "${PATCHSET_1_GIT_PATH}" -type f -name "*.patch" | ${PATCHSET_1_FILTER} | sort)

### Patchset 2 (optional)
if [ "$PATCHSET_2_BRANCH" != "" ]; then
  echo >&2 "===]> Info: Adding patchset 2 ... "
  git clone --single-branch --branch ${PATCHSET_2_BRANCH} ${PATCHSET_2_URL} \
    "${PATCHSET_2_GIT_PATH}"
  cd "${PATCHSET_2_GIT_PATH}" || exit
  git checkout ${PATCHSET_2_HASH}

  cd "${KERNEL_PATH}" || exit
  while IFS= read -r file; do
    echo "==> Adding ${file}"
    patch -p1 <"$file"
  done < <(find "${PATCHSET_2_GIT_PATH}" -type f -name "*.patch" | ${PATCHSET_2_FILTER} | sort)
fi

### Build process
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
make -j "$(getconf _NPROCESSORS_ONLN)" deb-pkg LOCALVERSION=-${RELEASE_SUFFIX} KDEB_PKGVERSION="${KERNEL_VERSION}-$(get_next_version ${RELEASE_SUFFIX})"

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... "
cp -rfv "${KERNEL_PATH}/.config" "${RELEASE_PATH}/kernel_config_${KERNEL_VERSION}"
cp -rfv ../*.deb "${RELEASE_PATH}"/
sha256sum ../*.deb > "${RELEASE_PATH}"/sha256

END_TIME=$(date +%s)
echo "Total execution took $((END_TIME-START_TIME)) seconds"
