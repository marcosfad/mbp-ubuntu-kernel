#!/bin/bash

set -eu -o pipefail

BUILD_PATH=/tmp/build-kernel

### Apple T2 drivers commit hashes
# Patches
APPLE_SMC_DRIVER_GIT_URL=https://github.com/aunali1/linux-mbp-arch.git
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=6386a7ff0871b9ec7101a0f6d92eee0b4307a859


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
