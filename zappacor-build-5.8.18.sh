#!/bin/bash

# Written by: Rolando Zappacosta
#   rolando_dot_zappacosta_at_nokia_dot_com

KERNEL_VERSION=5.8.18
KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL_VERSION.tar.xz
#
DRIVER_BCE_URL=https://github.com/t2linux/apple-bce-drv/archive/aur.zip
DRIVER_IBRIDGE_URL=https://github.com/roadrunner2/macbook12-spi-driver/archive/mbp15.zip
#
ZAPPACOR_PATCHES_KERNEL=./zappacor-patches-kernel-$KERNEL_VERSION
ZAPPACOR_PATCHES_BCE=./zappacor-patches-apple_bce-0.1.patch
ZAPPACOR_DEFCONF=./zappacor-config-5.8.18
ZAPPACOR_DOWNLOADS=./zappacor-downloads
ZAPPACOR_WORKDIR=./zappacor-work-dir


#####################################################
################## DOWNLOAD KERNEL ##################
#####################################################
mkdir -p $ZAPPACOR_DOWNLOADS
wget -c -P $ZAPPACOR_DOWNLOADS $KERNEL_URL
mkdir -p $ZAPPACOR_WORKDIR
tar xf $ZAPPACOR_DOWNLOADS/linux-$KERNEL_VERSION.tar.xz -C $ZAPPACOR_WORKDIR

##################################################################
################## APPLY UBUNTU AND SMC PATCHES ##################
##################################################################
# Ubuntu patches
#   From:
#     https://github.com/marcosfad/mbp-ubuntu-kernel/tree/master/patches
#   Excluded patches:
#     0004-debian-changelog.patch (from Marcos)
#   Not creating:
#     custom-drivers.patch
############################################################
# SMC patches
#   From:
#     https://github.com/aunali1/linux-mbp-archaunali1/linux-mbp-arch
#   Excluded patches:
#     wifi.patch (not needed)
#     000[0-9]* (excluded by Marcos, blindly doing the same):
#       0001-ZEN-Add-sysctl-and-CONFIG-to-disallow-unprivileged-C.patch
#       0002-virt-vbox-Add-support-for-the-new-VBG_IOCTL_ACQUIRE_.patch
#
(ZAPPACOR_PATCHES_KERNEL=`readlink -f $ZAPPACOR_PATCHES_KERNEL`
 cd $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION
 # This patch is on $ZAPPACOR_PATCHES_KERNEL but it's filtered out by the grep command on the
 # following line (just in case since some folks told Marcos it breaks their systems):
 #   2001-drm-amd-display-Force-link_rate-as-LINK_RATE_RBR2-fo.patch
 for PATCH_FILE in `ls -1 $ZAPPACOR_PATCHES_KERNEL| grep -vE '[2]00[0-9]'`; do
  echo "### Applying patch: `basename $PATCH_FILE`"
  patch -p1 <$ZAPPACOR_PATCHES_KERNEL/$PATCH_FILE
 done
)

####################################################
################## ADD BCE DRIVER ##################
####################################################
#   From: https://github.com/aunali1/mbp2018-bridge-drv.git (redirects to https://github.com/t2linux/apple-bce-drv)
#   Will show up as:
#   -> Device Drivers                                                                                                                                                                                 │  
#     -> Macintosh device drivers
#       -> Apple BCE driver (VHCI and Audio support)
# Download and decompress it
wget -c -O $ZAPPACOR_DOWNLOADS/apple-bce.zip $DRIVER_BCE_URL
unzip -d $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/ $ZAPPACOR_DOWNLOADS/apple-bce.zip -x '*/.gitignore'
mv $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-bce-drv-aur $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-bce
# Apply this patch to add a modalias to the driver so it can get automatically loaded on boot on a Mac with the T2 chip
(ZAPPACOR_PATCHES_BCE=`readlink -f $ZAPPACOR_PATCHES_BCE`
 cd $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION
  patch -p1 <$ZAPPACOR_PATCHES_BCE
)
# Create its Kconfig
printf 'config APPLE_BCE
\ttristate "Apple BCE driver (VHCI and Audio support)"
\tdefault m
\tdepends on X86
\tselect SOUND
\tselect SND
\tselect SND_PCM
\tselect SND_JACK
\thelp
\t  VHCI and audio support on Apple MacBook models 2018 and later.

\t  The project that implements this driver is divided in three components:
\t    - BCE (Buffer Copy Engine): which establishes a basic communication
\t      channel with the T2 chip. This component is required by the other two:
\t      - VHCI (Virtual Host Controller Interface): Access to keyboard, mouse
\t        and other system devices depend on this virtual USB host controller
\t      - Audio: a driver for the T2 audio interface (currently only audio
\t        output is supported).
\t 
\t  Please note that system suspend and resume are currently *not* supported.
\t  
\t  If "M" is selected, the module will be called apple-bce.' >$ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-bce/Kconfig
# Edit its Makefile
sed -i 's/obj-m/obj-$(CONFIG_APPLE_BCE)/g' $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-bce/Makefile
# Edit the kernel drivers Kconfig
sed -i "\$i source \"drivers/macintosh/apple-bce/Kconfig\"\n" $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/Kconfig
# Edit the kernel drivers Makefile
echo 'obj-$(CONFIG_APPLE_BCE)         += apple-bce/' >>$ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/Makefile

#########################################################
################## ADD IBRIDGE DRIVERS ##################
#########################################################
#   From: https://github.com/roadrunner2/macbook12-spi-driver
#   Will show up as:
#   -> Device Drivers                                                                                                                                                                                 │  
#     -> Macintosh device drivers
#       -> Apple iBridge driver (Touchbar and ALS support)
# Download and decompress it
wget -c -O $ZAPPACOR_DOWNLOADS/apple-ibridge.zip $DRIVER_IBRIDGE_URL
unzip -d $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/ $ZAPPACOR_DOWNLOADS/apple-ibridge.zip -x '*/.gitignore'
mv $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/macbook12-spi-driver-mbp15 $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-ibridge
# Create its Kconfig
printf 'config APPLE_IBRIDGE
\ttristate "Apple iBridge driver (Touchbar and ALS support)"
\tdefault m
\tdepends on X86
\tselect HID
\tselect IIO
\tselect IIO_TRIGGERED_BUFFER
\tselect IIO_BUFFER
\tselect ACPI_ALS
\thelp
\t  Work in progress driver for the Touchbar and ALS (Ambient
\t  Light Sensor) on 2019 and later Apple MacBook Pro computers.
\t  
\t  If "M" is selected, the modules will be called apple-ibridge,
\t  apple-ib-tb and apple-ib-als.' >$ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-ibridge/Kconfig
# Edit its Makefile file
sed -i 's/obj-m/obj-$(CONFIG_APPLE_IBRIDGE)/g' $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/apple-ibridge/Makefile
# Edit the kernel drivers Kconfig file
sed -i "\$i source \"drivers/macintosh/apple-ibridge/Kconfig\"\n" $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/Kconfig
# Edit the kernel drivers Makefile file
echo 'obj-$(CONFIG_APPLE_IBRIDGE)     += apple-ibridge/' >>$ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION/drivers/macintosh/Makefile

#################################################################
################## CONFIG AND BUILD THE KERNEL ##################
#################################################################
ZAPPACOR_DEFCONF=`readlink -f $ZAPPACOR_DEFCONF`
cd $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION
make clean
# Create a default kernel config 
cp $ZAPPACOR_DEFCONF .config
# Build it
make -j8 all
cd -

######################################################################
################## LOCAL COMPUTER TEST/INSTALLATION ##################
######################################################################
cd $ZAPPACOR_WORKDIR/linux-$KERNEL_VERSION
# Should check if the headers are really needed or not (guess they're not)
  make headers ; make headers_install
make modules_install
make install
cd -
# Need this for the Broadcom WiFi on my *HP laptop* to work (these following steps are *not* related to any Mac at all)
wget -c -P $ZAPPACOR_DOWNLOADS https://launchpad.net/ubuntu/+source/bcmwl/6.30.223.271+bdcom-0ubuntu7/+build/20102161/+files/bcmwl-kernel-source_6.30.223.271+bdcom-0ubuntu7_amd64.deb
apt install $ZAPPACOR_DOWNLOADS/bcmwl-kernel-source_6.30.223.271+bdcom-0ubuntu7_amd64.deb 

