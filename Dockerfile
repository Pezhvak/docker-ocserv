From alpine:latest

MAINTAINER Pezhvak

RUN apk update && apk add musl-dev iptables gnutls-dev gnutls-utils readline-dev libnl3-dev lz4-dev libseccomp-dev libev-dev

RUN buildDeps="xz openssl gcc autoconf make linux-headers"; \
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
	&& mkdir -p /etc/ocserv/data \
	&& cd \
	&& rm -rf ./$OC_FILE \
	&& apk del --purge $buildDeps

COPY ocserv.conf /etc/ocserv/ocserv.conf
RUN chmod 777 /etc/ocserv/ocserv.conf
COPY cn-no-route.txt /tmp/
RUN set -x \
        && sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \        
        && cat /tmp/cn-no-route.txt >> /etc/ocserv/ocserv.conf \
        && rm -rf /tmp/cn-no-route.txt \
        && touch /etc/ocserv/data/ocpaswd

WORKDIR /etc/ocserv

COPY docker-entrypoint.sh /root/entrypoint.sh
COPY ocuser /usr/local/bin/ocuser
RUN chmod 777 ~/entrypoint.sh
RUN chmod 777 /usr/local/bin/ocuser

RUN ls /etc/ocserv > /root/list
ENTRYPOINT ["/root/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
