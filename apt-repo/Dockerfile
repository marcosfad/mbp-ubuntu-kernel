FROM ubuntu:20.04

ARG RELEASE_VERSION=5.6.4
ARG GPG_KEY=some_key
ARG GPG_PASS=some_pass
ARG GPG_KEY_ID=some_id

ENV GITHUB_URL=github.com/marcosfad/mbp-ubuntu-kernel/releases
ENV REPO_URL=mbp-ubuntu-kernel.herokuapp.com
ENV LANG en_US.utf8

WORKDIR /var/repo

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      locales dpkg-dev dpkg-sig nginx gettext wget curl apt-utils \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN echo "${GPG_KEY}" > PRIVATE_GPG_KEY.asc \
    && gpg -v --batch --passphrase "${GPG_PASS}" --import PRIVATE_GPG_KEY.asc \
    && rm PRIVATE_GPG_KEY.asc \
    && gpg --list-keys \
    && gpg --output /var/repo/KEY.gpg --armor --export ${GPG_KEY_ID}

RUN for deb in $(curl -s https://${REPO_URL}/ -L | grep deb | grep a | cut -d'>' -f2 | cut -d'<' -f1); do \
      wget -q --backups=1 https://${REPO_URL}/${deb}; \
    done \
    ; rm -rfv *.1

RUN echo "${GPG_PASS}" > PRIVATE_GPG_PASS \
    && export GPG_TTY=$(tty) && \
    for deb in $(curl -s https://${GITHUB_URL}/latest -L | grep deb | grep span | cut -d'>' -f2 | cut -d'<' -f1); do \
      wget -q --backups=1 https://${GITHUB_URL}/download/v${RELEASE_VERSION}/${deb} && \
      dpkg-sig -k ${GPG_KEY_ID} -v --sign builder "./${deb}" \
        --gpg-options="--batch --pinentry-mode loopback --no-tty --passphrase-file ./PRIVATE_GPG_PASS"; \
    done \
    ; rm PRIVATE_GPG_PASS \
    ; rm -rfv *.1

RUN apt-ftparchive --arch amd64 packages . > Packages \
    && gzip -k -f Packages \
    && apt-ftparchive release . > Release

RUN echo "${GPG_PASS}" | gpg --batch --pinentry-mode loopback --yes --default-key "${GPG_KEY_ID}"\
          --passphrase-fd 0 -abs -o Release.gpg Release \
    && echo "${GPG_PASS}" | gpg --batch --pinentry-mode loopback --yes --default-key "${GPG_KEY_ID}"\
          --passphrase-fd 0 --clearsign -o InRelease Release

RUN chown -R www-data:www-data /var/repo && rm -rfv "/var/repo/${REPO_URL}" && ls -la /var/repo

COPY --chown=www-data:www-data nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/lib/nginx \
    && chown -R www-data:www-data /var/lib/nginx

RUN touch /var/run/nginx.pid && \
    chown -R www-data:www-data /var/run/nginx.pid

USER www-data

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf; cat /tmp/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
