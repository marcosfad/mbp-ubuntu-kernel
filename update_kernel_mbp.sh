#!/bin/bash

set -eu -o pipefail

### Apple T2 drivers commit hashes
KERNEL_PATCH_PATH=/tmp/kernel_patch

UPDATE_SCRIPT_BRANCH=${UPDATE_SCRIPT_BRANCH:-master}
APPLE_BCE_DRIVER_GIT_URL=https://github.com/aunali1/mbp2018-bridge-drv.git
APPLE_BCE_DRIVER_BRANCH_NAME=aur
APPLE_BCE_DRIVER_COMMIT_HASH=c884d9ca731f2118a58c28bb78202a0007935998
APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871

UBUNTU_KERNEL_REPO_URL=https://raw.githubusercontent.com/marcosfad/mbp-ubuntu-kernel
UBUNTU_KERNEL_RELEASES_URL=https://github.com/marcosfad/mbp-ubuntu-kernel/releases

if [ "$EUID" -ne 0 ]; then
  echo >&2 "===]> Please run as root --> sudo -i; update_kernel_mbp"
  exit
fi

rm -rf ${KERNEL_PATCH_PATH}
mkdir -p ${KERNEL_PATCH_PATH}
cd ${KERNEL_PATCH_PATH} || exit

### Downloading update_kernel_mbp script
echo >&2 "===]> Info: Downloading update_kernel_mbp ${UPDATE_SCRIPT_BRANCH} script... ";
rm -rf /usr/local/bin/update_kernel_mbp
if [ -f /usr/bin/update_kernel_mbp ]; then
  cp -rf /usr/bin/update_kernel_mbp ${KERNEL_PATCH_PATH}/
  ORG_SCRIPT_SHA=$(sha256sum ${KERNEL_PATCH_PATH}/update_kernel_mbp | awk '{print $1}')
fi
curl -L "${UBUNTU_KERNEL_REPO_URL}"/"${UPDATE_SCRIPT_BRANCH}"/update_kernel_mbp.sh \
    -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
if [ -f /usr/bin/update_kernel_mbp ]; then
  NEW_SCRIPT_SHA=$(sha256sum /usr/bin/update_kernel_mbp | awk '{print $1}')
  if [[ "$ORG_SCRIPT_SHA" != "$NEW_SCRIPT_SHA" ]]; then
    echo >&2 "===]> Info: update_kernel_mbp script was updated please rerun!" && exit
  else
    echo >&2 "===]> Info: update_kernel_mbp script is in the latest version proceeding..."
  fi
else
   echo >&2 "===]> Info: update_kernel_mbp script was installed..."
fi

### Download latest kernel
KERNEL_PACKAGES=()
if [[ ${1-} == "--rc" ]]; then
  echo >&2 "===]> Info: Downloading latest RC kernel... ";
  MBP_KERNEL_TAG=$(curl -sL "${UBUNTU_KERNEL_RELEASES_URL}" | grep deb | grep 'rc' | head -n 1 | cut -d'v' -f2 | cut -d'/' -f1)
  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL "${UBUNTU_KERNEL_RELEASES_URL}"/tag/v"${MBP_KERNEL_TAG}" | grep deb | grep span | cut -d'>' -f2 | cut -d'<' -f1 | grep -v dev)
else
  echo >&2 "===]> Info: Downloading latest stable kernel... ";
  MBP_KERNEL_TAG=$(curl -s "${UBUNTU_KERNEL_RELEASES_URL}"/latest | cut -d'v' -f2 | cut -d'"' -f1)
  while IFS='' read -r line; do KERNEL_PACKAGES+=("$line"); done <  <(curl -sL "${UBUNTU_KERNEL_RELEASES_URL}"/tag/v"${MBP_KERNEL_TAG}" | grep deb | grep span | cut -d'>' -f2 | cut -d'<' -f1 | grep -v dev)
fi

KERNEL_FULL_VERSION=${MBP_KERNEL_TAG}-mbp
echo >&2 "===]> Info: Installing kernel version: ${MBP_KERNEL_TAG} ";

for i in "${KERNEL_PACKAGES[@]}"; do
  curl -LO  "${UBUNTU_KERNEL_RELEASES_URL}"/download/v"${MBP_KERNEL_TAG}"/"${i}"
done

dpkg -i ./*.deb
apt-get install -f

[ -x "$(command -v gcc)" ] || apt-get install -y gcc

### Install custom drivers
## Apple BCE - Apple T2
cd ${KERNEL_PATCH_PATH} || exit
echo >&2 "===]> Info: Downloading BCE driver... ";
git clone --single-branch --branch ${APPLE_BCE_DRIVER_BRANCH_NAME} ${APPLE_BCE_DRIVER_GIT_URL} \
  "${KERNEL_PATCH_PATH}/apple-bce"
git -C "${KERNEL_PATCH_PATH}"/apple-bce/ checkout "${APPLE_BCE_DRIVER_COMMIT_HASH}"
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin \
  make -C /lib/modules/"${KERNEL_VERSION}"/build/ M="${KERNEL_PATCH_PATH}"/apple-bce modules
cp -rf "${KERNEL_PATCH_PATH}"/apple-bce/*.ko /lib/modules/"${KERNEL_VERSION}"/kernel/drivers/


## Touchbar
cd "${KERNEL_PATCH_PATH}"
echo >&2 "===]> Info: Downloading Touchbar driver... ";
git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} \
  "${KERNEL_PATCH_PATH}"/applespi
git -C "${KERNEL_PATCH_PATH}"/applespi/ checkout "${APPLE_IB_DRIVER_COMMIT_HASH}"
PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin \
  make -C /lib/modules/"${KERNEL_VERSION}"/build/ M="${KERNEL_PATCH_PATH}"/applespi modules
cp -rf "${KERNEL_PATCH_PATH}"/applespi/*.ko /lib/modules/"${KERNEL_VERSION}"/kernel/drivers/

### Add custom drivers to be loaded at boot
echo >&2 "===]> Info: Setting up GRUB to load custom drivers at boot... ";
printf '\n### apple-bce start ###\nhid-apple\nbcm5974\nsnd-seq\napple-bce\n### apple-bce end ###\n' >>/etc/modules-load.d/apple-bce.conf
printf '\n### applespi start ###\napple_ibridge\napple_ib_tb\napple_ib_als\n### applespi end ###\n' >>/etc/modules-load.d/applespi.conf
printf '\nblacklist thunderbolt' >/etc/modprobe.d/blacklist-thunderbold.conf

if grep -q '### apple-bce start ###' /etc/initramfs-tools/modules && grep -q '### apple-bce end ###' /etc/initramfs-tools/modules ; then
awk -v data="hid-apple\nsnd-seq\napple-bce" '
BEGIN {p=1}
/### apple-bce start ###/ {print; print data;p=0}
/### apple-bce end ###/ {p=1}
p' /etc/initramfs-tools/modules > /etc/initramfs-tools/modules
else
printf '\n### apple-bce start ###\nhid-apple\nsnd-seq\napple-bce\n### apple-bce end ###\n' >>/etc/initramfs-tools/modules
fi

GRUB_CMDLINE_VALUE=$(grep -v '#' /etc/default/grub | grep -w GRUB_CMDLINE_LINUX | cut -d'"' -f2)

for i in efi=noruntime pcie_ports=compat modprobe.blacklist=thunderbolt; do
  if ! echo "$GRUB_CMDLINE_VALUE" | grep -w $i; then
   GRUB_CMDLINE_VALUE="$GRUB_CMDLINE_VALUE $i"
  fi
done

sed -i "s:^GRUB_CMDLINE_LINUX=.*:GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_VALUE}\":g" /etc/default/grub

echo >&2 "===]> Info: Rebuilding initramfs with custom drivers... ";
depmod -a "${KERNEL_FULL_VERSION}"
update-initramfs -u -v -k "${KERNEL_FULL_VERSION}"

### Grub
echo >&2 "===]> Info: Rebuilding GRUB config... ";
curl -L https://github.com/marcosfad/mbp-ubuntu/blob/master/files/grub/30_os-prober -o /etc/grub.d/30_os-prober
chmod 755 /etc/grub.d/30_os-prober
grub-mkconfig -o /boot/grub/grub.cfg

### Cleanup
echo >&2 "===]> Info: Cleaning old kernel pkgs (leaving 3 latest versions)... ";
rm -rf ${KERNEL_PATCH_PATH}
apt autoremove -y
