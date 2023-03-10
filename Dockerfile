# Docker image for lenpaste using alpine template
ARG LICENSE="MIT"
ARG IMAGE_NAME="lenpaste"
ARG PHP_SERVER="lenpaste"
ARG TIMEZONE="America/New_York"
ARG BUILD_DATE="Thu Jan 5 10:18:21 AM EST 2023"
ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data"
ARG DEFAULT_CONF_DIR="/usr/local/share/template-files/config"
ARG DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG SERVICE_PORT="80"
ARG EXPOSE_PORTS="80/tcp"
ARG NODE_VERSION="system"
ARG NODE_MANAGER="system"
ARG BUILD_VERSION="latest"

FROM git.lcomrade.su/root/lenpaste:latest AS build

ARG ALPINE_VERSION=v3.16

ARG LICENSE \
  TIMEZONE \
  IMAGE_NAME \
  PHP_SERVER \
  BUILD_DATE \
  SERVICE_PORT \
  EXPOSE_PORTS \
  NODE_VERSION \
  NODE_MANAGER \
  BUILD_VERSION \
  DEFAULT_DATA_DIR \
  DEFAULT_CONF_DIR \
  DEFAULT_TEMPLATE_DIR

ARG PACK_LIST="bash tini"

ENV LANG=en_US.UTF-8
ENV ENV=ENV=~/.bashrc
ENV TZ="America/New_York"
ENV SHELL="/bin/sh"
ENV TERM="xterm-256color"
ENV TIMEZONE="${TZ:-$TIMEZONE}"
ENV HOSTNAME="casjaysdev-lenpaste"

COPY ./rootfs/. /

RUN set -ex; \
  rm -Rf "/etc/apk/repositories"; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main" >>"/etc/apk/repositories"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/community" >>"/etc/apk/repositories"; \
  if [ "${ALPINE_VERSION}" = "edge" ]; then echo "http://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/testing" >>"/etc/apk/repositories" ; fi ; \
  apk update --update-cache && apk add --no-cache ${PACK_LIST}

RUN [ -f "/entrypoint.sh" ] && rm -Rf "/entrypoint.sh" ; \
  [ -d "$DEFAULT_CONF_DIR/html" ] || mkdir -p "$DEFAULT_CONF_DIR/html" ; \
  [ -f "$DEFAULT_CONF_DIR/html/about" ] || touch "$DEFAULT_CONF_DIR/html/about" ; \
  [ -f "$DEFAULT_CONF_DIR/html/rules" ] || touch "$DEFAULT_CONF_DIR/html/rules" ; \
  [ -f "$DEFAULT_CONF_DIR/html/terms" ] || touch "$DEFAULT_CONF_DIR/html/terms"

RUN echo 'Running cleanup' ; \
  rm -Rf /usr/share/doc/* /usr/share/info/* /tmp/* /var/tmp/* ; \
  rm -Rf /usr/local/bin/.gitkeep /usr/local/bin/.gitkeep /config /data /var/cache/apk/* ; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* ; \
  rm -rf /etc/systemd/system/*.wants/* ; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* ; \
  rm -rf /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* ; \
  rm -rf /lib/systemd/system/systemd-update-utmp* ; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ]; then cd "/lib/systemd/system/sysinit.target.wants" && rm $(ls | grep -v systemd-tmpfiles-setup) ; fi

FROM scratch

ARG LICENSE \
  TIMEZONE \
  IMAGE_NAME \
  PHP_SERVER \
  BUILD_DATE \
  SERVICE_PORT \
  EXPOSE_PORTS \
  NODE_VERSION \
  NODE_MANAGER \
  BUILD_VERSION \
  DEFAULT_DATA_DIR \
  DEFAULT_CONF_DIR \
  DEFAULT_TEMPLATE_DIR

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.com>" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.name="${IMAGE_NAME}" \
  org.opencontainers.image.base.name="${IMAGE_NAME}" \
  org.opencontainers.image.license="${LICENSE}" \
  org.opencontainers.image.vcs-ref="${BUILD_VERSION}" \
  org.opencontainers.image.build-date="${BUILD_DATE}" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.schema-version="${BUILD_VERSION}" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}" \
  com.github.containers.toolbox="false"

ENV LANG=en_US.UTF-8 \
  ENV=~/.bashrc \
  SHELL="/bin/bash" \
  PORT="${SERVICE_PORT}" \
  TERM="xterm-256color" \
  PHP_SERVER="${PHP_SERVER}" \
  CONTAINER_NAME="${IMAGE_NAME}" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-${IMAGE_NAME}"

COPY --from=build /. /

USER root
WORKDIR /root

VOLUME [ "/config","/data" ]

EXPOSE $EXPOSE_PORTS

#CMD [ "" ]
ENTRYPOINT [ "tini", "-p", "SIGTERM", "--", "/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
