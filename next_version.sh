#!/bin/bash
VERSION=${1}
NEXT_VERSION=1
curl -s "https://github.com/marcosfad/mbp-ubuntu-kernel/releases/tag/v${VERSION}-${NEXT_VERSION}" -L | grep "linux-image-" > /dev/null
OLD_BUILD_EXIST=$?
if test $OLD_BUILD_EXIST -eq 0
then
  NEXT_VERSION=$((LATEST_BUILD+1))
  LATEST_BUILD=$(./next_version.sh "${VERSION}-${NEXT_VERSION}")
else
  LATEST_BUILD=0
fi
echo "$((LATEST_BUILD+1))"
