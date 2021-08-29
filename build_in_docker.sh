#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=ubuntu:20.04

# https://kernel.ubuntu.com/~kernel-ppa/mainline/
# https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/focal
docker pull ${DOCKER_IMAGE}

# Aunali1
VERSION=$(ubuntu-mainline-kernel.sh -r v5.12 | grep v | rev | cut -d'v' -f 1 | rev | tail -1)
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=${VERSION} \
      --kernelBranch=v${VERSION} \
      --kernelRepository='git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git' \
      --patchset1Repo='git://github.com/aunali1/linux-mbp-arch.git' \
      --patchset1Branch=master \
      --patchset1Commit=9511d5ed2ae0e851dd6a82843daefb2be7d5e212 \
      --patchset1Filter=\"grep -vE 000[0-9]\" \
      --releaseSuffix=t2-aunali1 \
      --releasePath=/repo/build/t2-aunali1 \
"
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=${VERSION} \
      --kernelBranch=v${VERSION} \
      --kernelRepository='git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git' \
      --patchset1Repo='git://github.com/aunali1/linux-mbp-arch.git' \
      --patchset1Branch=master \
      --patchset1Commit=9511d5ed2ae0e851dd6a82843daefb2be7d5e212 \
      --patchset1Filter=\"grep -vE 000[0-9]\" \
      --patchset2Repo='git://github.com/jamlam/mbp-16.1-linux-wifi.git' \
      --patchset2Branch=main \
      --patchset2Commit=843ecfcaaec0a10707d447ac6d1840db940a9d29 \
      --patchset2Filter=\"grep -E 8001\" \
      --releaseSuffix=t2-aunali1-patched \
      --releasePath=/repo/build/t2-aunali1-patched \
"
## jamlam
VERSION=$(ubuntu-mainline-kernel.sh -r v5.13 | grep v | rev | cut -d'v' -f 1 | rev | tail -1)
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=${VERSION} \
      --kernelBranch=v${VERSION} \
      --kernelRepository='git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git' \
      --patchset1Repo='git://github.com/jamlam/mbp-16.1-linux-wifi.git' \
      --patchset1Branch=main \
      --patchset1Commit=843ecfcaaec0a10707d447ac6d1840db940a9d29 \
      --patchset1Filter=\"grep -vE 0001|800[0-9]\" \
      --releaseSuffix=t2-jamlam \
      --releasePath=/repo/build/t2-jamlam \
"

docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=${VERSION} \
      --kernelBranch=v${VERSION} \
      --kernelRepository='git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git' \
      --patchset1Repo='git://github.com/jamlam/mbp-16.1-linux-wifi.git' \
      --patchset1Branch=main \
      --patchset1Commit=843ecfcaaec0a10707d447ac6d1840db940a9d29 \
      --patchset1Filter=\"grep -vE 0001|800[0-9]\" \
      --patchset2Repo='git://github.com/aunali1/linux-mbp-arch.git' \
      --patchset2Branch=master \
      --patchset2Commit=9511d5ed2ae0e851dd6a82843daefb2be7d5e212 \
      --patchset2Filter=\"grep -E brcmfmac\" \
      --releaseSuffix=t2-jamlam-patched
      --releasePath=/repo/build/t2-jamlam-patched \
"

# HWE
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=5.11.0 \
      --kernelBranch=Ubuntu-hwe-5.11-5.11.0-34.36_20.04.1 \
      --kernelRepository='git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/focal' \
      --debianSaucePatches=no \
      --patchset1Repo='git://github.com/AdityaGarg8/5.10-patches.git' \
      --patchset1Branch=main \
      --patchset1Commit=e509d58d4127ecd9c17292560f10fc089f1ad030 \
      --patchset1Filter=\"grep -vE 0001\" \
      --releaseSuffix=t2-hwe \
      --releasePath=/repo/build/t2-hwe \
"
docker run \
  -t \
  --rm \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "\
    cd /repo \
    && \
    ./build.sh \
      --kernel=5.13.0 \
      --kernelBranch=Ubuntu-hwe-5.13-5.13.0-14.14_20.04.2 \
      --kernelRepository='git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/focal' \
      --debianSaucePatches=no \
      --patchset1Repo='git://github.com/jamlam/mbp-16.1-linux-wifi.git' \
      --patchset1Branch=main \
      --patchset1Commit=843ecfcaaec0a10707d447ac6d1840db940a9d29 \
      --patchset1Filter=\"grep -vE 0001\" \
      --releaseSuffix=t2-hwe-next \
      --releasePath=/repo/build/t2-hwe-next \
"
