FROM ubuntu:20.04

ARG RELEASE_VERSION=5.6.4

WORKDIR /var/repo

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales dpkg-dev dpkg-sig nginx gettext wget curl apt-utils \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN wget -A deb -r https://mbp-ubuntu-kernel.herokuapp.com/ \
    && mv -f ./mbp-ubuntu-kernel.herokuapp.com/*.deb ./ \
    && rm -rfv mbp-ubuntu-kernel.herokuapp.com \
    ; rm -rfv *.1

RUN for deb in $(curl -s https://github.com/marcosfad/mbp-ubuntu-kernel/releases/latest -L | grep deb | grep span | cut -d'>' -f2 | cut -d'<' -f1); do \
      wget --backups=1 https://github.com/marcosfad/mbp-ubuntu-kernel/releases/download/v${RELEASE_VERSION}/$deb; \
    done \
    ; rm -rfv *.1 \
    ; chown -R www-data:www-data /var/repo

RUN apt-ftparchive --arch amd64 packages . > Packages \
    && gzip -k -f Packages \
    && apt-ftparchive release . > Release
#    rm -fr Release.gpg; gpg --default-key ${KEYNAME} -abs -o Release.gpg Release
#    rm -fr InRelease; gpg --default-key ${KEYNAME} --clearsign -o InRelease Release

COPY --chown=www-data:www-data nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/lib/nginx \
    && chown -R www-data:www-data /var/lib/nginx

RUN touch /var/run/nginx.pid && \
    chown -R www-data:www-data /var/run/nginx.pid

USER www-data

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf; cat /tmp/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
