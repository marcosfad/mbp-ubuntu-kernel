#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
# BCE_DRIVER_GIT_URL=https://github.com/MCMrARM/mbp2018-bridge-drv.git
# BCE_DRIVER_BRANCH_NAME=master
# BCE_DRIVER_COMMIT_HASH=7330e638b9a32b4ae9ea97857f33838b5613cad3
# APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
# APPLE_IB_DRIVER_BRANCH_NAME=mbp15
# APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871
APPLE_SMC_DRIVER_GIT_URL=https://github.com/aunali1/linux-mbp-arch
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=9f126dac0c297996611913b58ff50824c9c42efb
# BT_PATCH_NAME="2001-serdev-Fix-detection-of-UART-devices-on-Apple-machin.patch"

REPO_PWD=$(pwd)

mkdir -p /tmp/build-kernel
cd /tmp/build-kernel || exit

### AppleSMC mrarm
# git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
# cd mbp2018-etc || exit
# git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
# cd ..
# [ ! -d mbp2018-etc/applesmc/patches ] && { echo 'AppleSMC patches directory not found!'; exit 1; }
# while IFS= read -r file; do
#   echo "adding ${file}"
#   cp -rfv "${file}" "${REPO_PWD}"/../patches/"${file##*/}"
# done < <(find mbp2018-etc/applesmc/patches/ -type f | sort)

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL}
cd linux-mbp-arch || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
cd ..
while IFS= read -r file; do
  echo "adding ${file}"
  cp -rfv "${file}" "${REPO_PWD}"/../patches/"${file##*/}"
done < <(find linux-mbp-arch -type f -name "*applesmc*" | sort)
# cp -rfv ./linux-mbp-arch/"$BT_PATCH_NAME" "${REPO_PWD}"/../patches/
rm -rf /tmp/build-kernel

### Add custom drivers to kernel
# echo -e "From: fedora kernel <fedora@kernel.org>\nSubject: patch custom drivers\n" > "${REPO_PWD}"/../patches/custom-drivers.patch

# git clone --depth 1 --single-branch --branch v"${FEDORA_KERNEL_VERSION}" git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# cd ./linux-stable/drivers || exit

# ### bce
# git clone --depth 1 --single-branch --branch ${BCE_DRIVER_BRANCH_NAME} ${BCE_DRIVER_GIT_URL} ./bce
# cd bce || exit
# git checkout ${BCE_DRIVER_COMMIT_HASH}

# rm -rf .git
# cd ..
# cp -rfv "${REPO_PWD}"/../templates/Kconfig bce/Kconfig
# sed -i "s/TEST_DRIVER/BCE_DRIVER/g" bce/Kconfig
# # shellcheck disable=SC2016
# sed -i 's/obj-m/obj-$(CONFIG_BCE)/g' bce/Makefile

# ### apple-ib
# git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} touchbar
# cd touchbar || exit
# git checkout ${APPLE_IB_DRIVER_COMMIT_HASH}
# rm -rf .git
# cd ..
# cp -rfv "${REPO_PWD}"/../templates/Kconfig touchbar/Kconfig
# sed -i "s/TEST_DRIVER/TOUCHBAR_DRIVER/g" touchbar/Kconfig
# # shellcheck disable=SC2016
# sed -i 's/obj-m/obj-$(CONFIG_TOUCHBAR)/g' touchbar/Makefile

# # shellcheck disable=SC2016
# echo 'obj-$(CONFIG_BCE)           += bce/' >> ./Makefile
# # shellcheck disable=SC2016
# echo 'obj-$(CONFIG_TOUCHBAR)           += touchbar/' >> ./Makefile
# sed -i "\$i source \"drivers/bce/Kconfig\"\n" Kconfig
# sed -i "\$i source \"drivers/touchbar/Kconfig\"\n" Kconfig

# ### Prepare patch
# git add .
# git diff HEAD >> "${REPO_PWD}"/../patches/custom-drivers.patch

# ### back to fedora kernel repo
# cd "$REPO_PWD" || exit
# find . -type f -name "*.config" -exec sh -c '
#   echo "CONFIG_BCE_DRIVER=m" >> $1
#   echo "CONFIG_TOUCHBAR_DRIVER=m" >> $1
# ' sh {} \;

# echo 'CONFIG_BCE_DRIVER=m' > configs/fedora/generic/CONFIG_BCE_DRIVER
# echo 'CONFIG_TOUCHBAR_DRIVER=m' >> configs/fedora/generic/CONFIG_TOUCHBAR_DRIVER

# echo -e "bce.ko\napple-ib-als.ko\napple-ib-tb.ko\napple-ibridge.ko" >> mod-extra.list
# echo 'inputdrvs="gameport tablet touchscreen bce touchbar"' >> filter-x86_64.sh

# ### Remove thunderbolt driver
# sed -i "s/CONFIG_THUNDERBOLT=m/CONFIG_THUNDERBOLT=n/g" kernel-x86_64*
# sed -i "s/CONFIG_THUNDERBOLT=m/CONFIG_THUNDERBOLT=n/g" configs/fedora/generic/x86/x86_64/CONFIG_THUNDERBOLT
