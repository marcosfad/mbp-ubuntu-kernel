#!/bin/bash

set -eu -o pipefail

BUILD_PATH=/tmp/build-kernel

### Apple T2 drivers commit hashes
# Patches
APPLE_SMC_DRIVER_GIT_URL=https://github.com/jamlam/mbp-16.1-linux-wifi.git
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=46e4665e286862d76d29701a334515a77734c58f


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
