From alpine:latest
MAINTAINER Pezhvak

ARG ORGANIZATION="My Corp"
ARG DOMAIN="example.com"
ARG PORT=1243

RUN apk update && apk add musl-dev iptables gnutls-dev readline-dev libnl3-dev lz4-dev libseccomp-dev@testing

RUN buildDeps="xz openssl gcc autoconf make linux-headers libev-dev"; \
	set -x \
	&& apk add $buildDeps \
	&& cd \
	&& wget http://ocserv.gitlab.io/www/download.html -O download.html \
	&& OC_VERSION=`sed -n 's/^.*version is <b>\(.*\)$/\1/p' download.html` \
	&& OC_FILE="ocserv-$OC_VERSION" \
	&& rm -fr download.html \
	&& wget ftp://ftp.infradead.org/pub/ocserv/$OC_FILE.tar.xz \
	&& tar xJf $OC_FILE.tar.xz \
	&& rm -fr $OC_FILE.tar.xz \
	&& cd $OC_FILE \
	&& sed -i '/#define DEFAULT_CONFIG_ENTRIES /{s/96/200/}' src/vpn.h \
	&& ./configure \
	&& make -j"$(nproc)" \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cd \
	&& rm -rf ./$OC_FILE \
	&& apk del --purge $buildDeps

COPY cn-no-route.txt /tmp/
RUN set -x \
	&& sed -i "s/tcp-port = 443/tcp-port = ${PORT}/" /etc/ocserv/ocserv.conf \
        && sed -i "s/udp-port = 443/udp-port = ${PORT}/" /etc/ocserv/ocserv.conf \
        && sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \        
        && cat /tmp/cn-no-route.txt >> /etc/ocserv/ocserv.conf \
        && rm -fr /tmp/cn-no-route.txt
        && touch /etc/ocserv/ocpaswd

WORKDIR /etc/ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE $PORT
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
