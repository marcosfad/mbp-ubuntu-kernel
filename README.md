# mbp-ubuntu-kernel

Ubuntu/Mint/Debian kernel 5.6 with Apple T2 patches built-in (Macbooks produced >= 2018).

Drivers:

- Apple T2 (audio, keyboard, touchpad) - <https://github.com/MCMrARM/mbp2018-bridge-drv>
- Apple SMC - <https://github.com/MCMrARM/mbp2018-etc>
- Touchbar - <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

This project is closely inspired by mikeeq/mbp-fedora-kernel. Thank you @mikeeq for the scripts and setup.

IF YOU ENJOY THIS CODE, CONSIDER CONTRIBUTING TO THE AUTHORS @MCMrARM @roadrunner2 @aunali1 @ppaulweber @mikeeq, they did all the hard work.

## CI status

Drone kernel build status:
[![Build Status](https://cloud.drone.io/api/badges/marcosfad/mbp-ubuntu-kernel/status.svg)](https://cloud.drone.io/marcosfad/mbp-ubuntu-kernel)

Travis kernel publish status - <http://mbp-ubuntu-kernel.herokuapp.com/> :
[![Build Status](https://travis-ci.com/marcosfad/mbp-ubuntu-kernel.svg?branch=master)](https://travis-ci.com/marcosfad/mbp-ubuntu-kernel)

## TODO

### Known issues

- Dynamic audio input/output change (on connecting/disconnecting headphones jack)
- TouchID - (@MCMrARM is working on it - https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490)
- Thunderbolt (is disabled, because driver was causing kernel panics (not tested with 5.5 kernel))
- Microphone (it's recognised with new apple t2 sound driver, but there is a low mic volume amp)

#### Working with upstream stable kernel 5.1

- Display/Screen
- USB-C
- Battery/AC
- Ethernet/Video USB-C adapters
- Bluetooth

#### Working with mbp-ubuntu-kernel

- NVMe
- Camera
- keyboard
- touchpad (scroll, right click)
- wifi (not Macbook pro 16,1)
  - you need to manually extract firmware from macOS
    - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-517444300>
    - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-515401480>
  - or download it from <https://packages.aunali1.com/apple/wifi-fw/18G2022>

> Firmware can be found by running `ioreg -l | grep C-4364` or `ioreg -l | grep RequestedFiles` under macOS

```
Put the firmware in the right place!
The .trx file for your model goes to /lib/firmware/brcm/brcmfmac4364-pcie.bin,
the .clmb goes to /lib/firmware/brcm/brcmfmac4364-pcie.clm_blob
and the .txt to something like /lib/firmware/brcm/brcmfmac4364-pcie.Apple Inc.-MacBookPro15,2.txt
```

```
# ls -l /lib/firmware/brcm | grep 4364
-rw-r--r--. 1 root root   12860 Mar  1 12:44 brcmfmac4364-pcie.Apple Inc.-MacBookPro15,2.txt
-rw-r--r--. 1 root root  922647 Mar  1 12:44 brcmfmac4364-pcie.bin
-rw-r--r--. 1 root root   33226 Mar  1 12:44 brcmfmac4364-pcie.clm_blob
```

```
# dmesg
brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4364-pcie for chip BCM4364/3
brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4364-pcie for chip BCM4364/3
brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4364/3 wl0: Mar 28 2019 19:17:52 version 9.137.9.0.32.6.34 FWID 01-36f56c94
brcmfmac 0000:01:00.0 wlp1s0: renamed from wlan0
```

#### Working with external drivers

>> with @MCMrARM mbp2018-bridge-drv

- keyboard
- touchpad
- touchbar
- audio

#### Not tested

- eGPU
- Thunderbolt

## Docs

- Discord: <https://discord.gg/Uw56rqW>
- WiFi firmware: <https://packages.aunali1.com/apple/wifi-fw/18G2022>
- blog `Installing Fedora 31 on a 2018 Mac mini`: <https://linuxwit.ch/blog/2020/01/installing-fedora-on-mac-mini/>
- iwd:
  - <https://iwd.wiki.kernel.org/networkconfigurationsettings>
  - <https://wiki.archlinux.org/index.php/Iwd>
  - <https://www.vocal.com/secure-communication/eap-types/>

### Ubuntu

- <https://wiki.ubuntu.com/KernelTeam/GitKernelBuild>
- <https://help.ubuntu.com/community/Repositories/Personal>

### Github

- GitHub issue (RE history): <https://github.com/Dunedan/mbp-2016-linux/issues/71>
- VHCI+Sound driver (Apple T2): <https://github.com/MCMrARM/mbp2018-bridge-drv/>
- AppleSMC driver (fan control): <https://github.com/MCMrARM/mbp2018-etc/tree/master/applesmc>
- hid-apple keyboard backlight patch: <https://github.com/MCMrARM/mbp2018-etc/tree/master/apple-hid>
- TouchBar driver: <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>
- Kernel patches (all are mentioned in github issue above): <https://github.com/aunali1/linux-mbp-arch>
- ArchLinux kernel patches: <https://github.com/ppaulweber/linux-mba>
- hid-apple-patched module for changing mappings of ctrl, fn, option keys: <https://github.com/free5lot/hid-apple-patched>

## Credits

- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @mikeeq - thanks for the fedora kernel project and compilation scripts
