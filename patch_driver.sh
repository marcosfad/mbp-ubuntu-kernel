#!/bin/bash

set -eu -o pipefail

BUILD_PATH=/tmp/build-kernel

### Apple T2 drivers commit hashes
# Patches
APPLE_SMC_DRIVER_GIT_URL=https://github.com/aunali1/linux-mbp-arch.git
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=1faa37d704798bc04104a88f620e4f55b3466de0

### alternate wifi patches for mbp15,4, mbp16,* and mba9,1
# Patches
ALT_WIFI_DRIVER_GIT_URL=https://github.com/AdityaGarg8/5.10-patches.git
ALT_WIFI_DRIVER_BRANCH_NAME=main
ALT_WIFI_DRIVER_COMMIT_HASH=5fa2b9e8cffb66a8cbf25cc55ec9d40279c2c801


rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"
cd "${BUILD_PATH}" || exit

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL} \
  "${BUILD_PATH}/linux-mbp-arch"
cd "${BUILD_PATH}/linux-mbp-arch" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}

while IFS= read -r file; do
  echo "==> Adding ${file}"
  cp -rfv "${file}" "${WORKING_PATH}"/patches/"${file##*/}"
done < <(find "${BUILD_PATH}/linux-mbp-arch" -type f -name "*.patch" | sort)

### alternate wifi patches for mbp15,4, mbp16,* and mba9,1
git clone --single-branch --branch ${ALT_WIFI_DRIVER_BRANCH_NAME} ${ALT_WIFI_DRIVER_GIT_URL} \
  "${BUILD_PATH}/mbp-16.1-linux-wifi"
cd "${BUILD_PATH}/mbp-16.1-linux-wifi" || exit
git checkout ${ALT_WIFI_DRIVER_COMMIT_HASH}

while IFS= read -r file; do
  echo "==> Adding ${file}.alt_wifi_only"
  cp -rfv "${file}" "${WORKING_PATH}"/patches/"${file##*/}.alt_wifi_only"
done < <(find "${BUILD_PATH}/mbp-16.1-linux-wifi" -type f -name "8*.patch" | sort)
