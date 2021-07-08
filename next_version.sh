#!/bin/bash
curl -s https://mbp-ubuntu-kernel.herokuapp.com/ -L | grep "linux-image-${KERNEL_VERSION}-§" > /dev/null
OLD_BUILD_EXIST=$?
if test $OLD_BUILD_EXIST -eq 0
then
  LATEST_BUILD=$(curl -s https://mbp-ubuntu-kernel.herokuapp.com/ -L | grep "linux-image-${KERNEL_VERSION}-${1}" |
    grep a | cut -d'>' -f2 | cut -d'<' -f1 |
    sort -r | head -n 1 | cut -d'-' -f6 | cut -d'_' -f1)
else
  LATEST_BUILD=0
fi
echo "$((LATEST_BUILD+1))"
