FROM alpine:latest

MAINTAINER Pezhvak

RUN apk update && apk add musl-dev iptables gnutls-dev gnutls-utils readline-dev libnl3-dev lz4-dev libseccomp-dev libev-dev

RUN buildDeps="xz openssl gcc autoconf make linux-headers"; \
	set -x \
	&& apk add $buildDeps \
	&& cd \
	&& wget http://ocserv.gitlab.io/www/download.html -O download.html \
	&& OC_VERSION=`sed -n 's/^.*The latest version of ocserv is \(.*\)$/\1/p' download.html` \
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
	&& mkdir -p /etc/ocserv/data \
	&& cd \
	&& rm -rf ./$OC_FILE \
	&& apk del --purge $buildDeps

COPY config/ocserv.conf /etc/ocserv/ocserv.conf
RUN chmod 655 /etc/ocserv/ocserv.conf
COPY config/no-route.txt /tmp/
RUN set -x \
        && sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \        
        && cat /tmp/no-route.txt >> /etc/ocserv/ocserv.conf \
        && rm -rf /tmp/no-route.txt \
        && touch /etc/ocserv/data/ocpaswd

WORKDIR /etc/ocserv

COPY scripts/docker-entrypoint.sh /root/entrypoint.sh
COPY scripts/ocuser /usr/local/bin/ocuser
RUN chmod +x ~/entrypoint.sh
RUN chmod +x /usr/local/bin/ocuser

ENTRYPOINT ["/root/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
