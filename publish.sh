#!/bin/bash

set -eu -o pipefail

# export HEROKU_API_KEY=

cd apt-repo || exit

# Download heroku-cli
curl https://cli-assets.heroku.com/install.sh | sh

heroku container:login
heroku container:push -a mbp-ubuntu-kernel web \
  --arg GPG_KEY_ID="${GPG_KEY_ID}",GPG_PASS="${GPG_PASS}",GPG_KEY="${GPG_KEY}"
heroku container:release -a mbp-ubuntu-kernel web

# Docker build
#docker build -t mbp-ubuntu-kernel --build-arg RELEASE_VERSION="${LATEST_RELEASE}" .
#docker build -t mbp-ubuntu-kernel  .
