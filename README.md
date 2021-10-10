# mbp-ubuntu-kernel

Ubuntu/Mint/Debian kernel 5.6+ with Apple T2 patches built-in. This repo try to keep up with kernel new releases.

We release a matrix of kernels to allow you to test with which works the best for you. The main difference are
* the source used for building the kernel: kernel.org vs Ubuntu HWE
* the patchset used ([Aunali1](https://github.com/aunali1/linux-mbp-arch) or [Jamlam](https://github.com/jamlam/mbp-16.1-linux-wifi)) and with that the combination of which wifi driver you need. (See [WiFi guide](https://wiki.t2linux.org/guides/wifi/) for more information).

I suggest always starting with the Ubuntu HWE Kernels I have great stability with them.

The old type of releases are now deprecated and should not be used.

**Drivers included:**

- Apple T2 (audio, keyboard, touchpad) - <https://github.com/MCMrARM/mbp2018-bridge-drv>
- Apple SMC - <https://github.com/MCMrARM/mbp2018-etc>
- Touchbar - <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

This project is closely inspired by mikeeq/mbp-fedora-kernel. Thank you @mikeeq for the scripts and setup.

**If this repo helped you in any way, consider inviting a coffee to the people in the [credits](https://github.com/marcosfad/mbp-ubuntu-kernel#credits) or [me](https://paypal.me/marcosfad)**

## INSTALLATION

### The easy way

Use the [mbp-ubuntu](https://github.com/marcosfad/mbp-ubuntu/releases) live cd to install ubuntu on your Mac.

### Manually using the apt repository

Add the repo to your apt sources
```bash
echo "deb https://mbp-ubuntu-kernel.herokuapp.com/ /" >/etc/apt/sources.list.d/mbp-ubuntu-kernel.list
curl -L https://mbp-ubuntu-kernel.herokuapp.com/KEY.gpg | apt-key add -
apt-get update
```
Install the kernel using apt, for example kernel 5.10.47:
```bash
apt-get install linux-headers-5.10.47-mbp linux-image-5.10.17-mbp
```

### Manually downloading the kernel from the Github releases

* Download the release you want to try: linux-image-* linux-headers-* to a folder
* `cd <folder>`
* `sudo dpkg -i *.deb`

## Docs

- Discord: <https://discord.gg/Uw56rqW>
- WiFi guide: <https://wiki.t2linux.org/guides/wifi/>
- blog `Installing Fedora 31 on a 2018 Mac mini`: <https://linuxwit.ch/blog/2020/01/installing-fedora-on-mac-mini/>
- iwd:
  - <https://iwd.wiki.kernel.org/networkconfigurationsettings>
  - <https://wiki.archlinux.org/index.php/Iwd>
  - <https://www.vocal.com/secure-communication/eap-types/>

### Ubuntu

- <https://wiki.ubuntu.com/KernelTeam/GitKernelBuild>
- <https://help.ubuntu.com/community/Repositories/Personal>
- <https://medium.com/sqooba/create-your-own-custom-and-authenticated-apt-repository-1e4a4cf0b864>
- <https://help.ubuntu.com/community/Kernel/Compile>
- <https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel>
- <https://www.linux.com/training-tutorials/kernel-newbie-corner-building-and-running-new-kernel/>
- <https://wiki.ubuntu.com/KernelTeam/KernelMaintenance>

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
- @aunali1 - thanks for ArchLinux Kernel CI and active support.
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @mikeeq - thanks for the fedora kernel project and compilation scripts
