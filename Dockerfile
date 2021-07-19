FROM alpine

ARG XYMON_VERSION=4.3.30
ARG XYMON_SHA256SUM=8ed51771c8e1e15df96725072c61a21286ab0e6105a0e1edac956225201bf5f5

WORKDIR /build

RUN addgroup -S xymon && adduser -S -G xymon xymon

RUN apk add lighttpd build-base fping \
  pcre-dev c-ares-dev rrdtool-dev \
  openssl-dev openldap-dev libtirpc-dev

ADD https://phoenixnap.dl.sourceforge.net/project/xymon/Xymon/${XYMON_VERSION}/xymon-${XYMON_VERSION}.tar.gz .

RUN echo "${XYMON_SHA256SUM}  xymon-${XYMON_VERSION}.tar.gz" | sha256sum -c - \
  && tar --strip-components 1 -xf xymon-${XYMON_VERSION}.tar.gz

RUN \
  sed -i "s/${XYMON_VERSION}/${XYMON_VERSION}.docker/" include/version.h && \
  USEXYMONPING=n \
  USERFPING=/usr/sbin/fping \
  ENABLESSL=y SSLOK=YES \
  ENABLELDAP=y \
  ENABLELDAPSSL=y \
  CONFTYPE=server \
  XYMONUSER=xymon \
  XYMONTOPDIR=/usr/share/xymon \
  XYMONVAR=/var/lib/xymon \
  XYMONHOSTURL=/ \
  CGIDIR=/usr/share/xymon/cgi-bin \
  XYMONCGIURL=/xymon-cgi \
  SECURECGIDIR=/usr/share/xymon/cgi-secure \
  SECUREXYMONCGIURL=/xymon-seccgi \
  HTTPDGID=lighttpd \
  XYMONLOGDIR=/var/log/xymon \
  XYMONRUNDIR=/run/xymon \
  XYMONHOSTNAME=localhost \
  XYMONHOSTIP=127.0.0.1 \
  MANROOT=/usr/share/man \
  INSTALLLIBDIR=/usr/lib \
  INSTALLBINDIR=/usr/libexec/xymon \
  INSTALLETCDIR=/etc/xymon \
  INSTALLEXTDIR=/etc/xymon/ext \
  INSTALLWEBDIR=/etc/xymon/web \
  INSTALLTMPDIR=/run/xymon \
  INSTALLWWWDIR=/var/www/localhost/htdocs \
  INSTALLSTATICWWWDIR=/var/cache/xymon \
  ./configure

RUN \
  make && make V=1 PKGBUILD=1 INSTALLROOT=/xymon install

FROM alpine

LABEL maintainer="silooslabs <https://silooslabs.github.io>"

RUN addgroup -S xymon && adduser -S -G xymon xymon

RUN apk add --no-cache fping \
  procps net-tools coreutils \
  pcre c-ares rrdtool \
  openssl openldap libtirpc tini su-exec \
  tzdata ttf-droid lighttpd ssmtp mailx

COPY --from=0 --chown=xymon:xymon /xymon /
COPY --chown=xymon:xymon files /
COPY docker-entrypoint.sh /usr/local/bin/

RUN \
  sed -i -E 's,\-\-pidfile=\$XYMONSERVERLOGS/([a-z_]+)\.pid,\-\-pidfile=\$XYMONRUNDIR/\1\.pid,' etc/xymon/tasks.cfg \
  && echo -e '\ninclude "xymon.conf"' >> /etc/lighttpd/lighttpd.conf \
  && echo -e '\npage dynamic-hosts Dynamically Discovered Hosts\ninclude ghostlist.cfg' >> etc/xymon/hosts.cfg \
  && tar --exclude '*.conf' --exclude '*.bak' -czf /root/xymon-config.tgz etc/xymon \
  && tar -czf /root/xymon-data.tgz var/lib/xymon

VOLUME ["/var/lib/xymon", "/etc/xymon"]

EXPOSE 1984 80

ENV \
  XYMONRUNDIR=/run/xymon \
  XYMONCLIENTHOME=/usr/share/xymon/client \
  PATH=/usr/libexec/xymon:${PATH}

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["docker-entrypoint.sh"]
