ARG OLS_VERSION=1.6.18
ARG PHP_VERSION=lsphp74
FROM litespeedtech/openlitespeed:$OLS_VERSION-$PHP_VERSION

# Install Package Requirement
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    wget \
    rsync \
    unzip \
    inotify-tools \
    openssh-server; \
    rm -rf /var/lib/apt/lists/*

# Setup SSH
#RUN set -ex; \
#    rm -f /etc/ssh/sshd_config
COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /etc/ssh/
RUN set -ex; \
    echo "root:Docker!" | chpasswd; \
    chmod -R +x /etc/ssh/ssh_setup.sh; \
    (sleep 1;. /etc/ssh/ssh_setup.sh 2>&1 > /dev/null); \
    rm -rf /etc/ssh/ssh_setup.sh

# Install oSync
ADD https://github.com/deajan/osync/archive/v1.3-beta3.tar.gz /root/osync.tar.gz
COPY sync.conf /usr/src/php/
RUN set -ex; \
    cd /root; \
    if ! [ -f /sbin/init ]; then touch /sbin/init; REM_INIT=1; fi; \
    tar xvf osync.tar.gz; \
    cd osync-1.3-beta3/; \
    set +e; \
    ./install.sh --no-stats; \
    set -ex; \
    if [ "$REM_INIT" = "1" ]; then rm -f /sbin/init; fi; \
    cd ..; \
    rm -rf osync*; \
    chmod 444 /usr/src/php/sync.conf

# Install composer
RUN set -ex; \
    EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"; \
	curl -o composer-setup.php -fSL "https://getcomposer.org/installer"; \
	echo "$EXPECTED_CHECKSUM *composer-setup.php" | sha384sum -c -; \
    mkdir -p /usr/src/composer; \
	php composer-setup.php --install-dir=/usr/src/composer; \
	rm composer-setup.php; \
    ln -s /usr/src/composer/composer.phar /usr/local/bin/composer

# Configure LiteSpeed
COPY phpsite.conf /usr/local/lsws/conf/templates/
COPY httpd_config.conf /usr/local/lsws/conf/
RUN chown 999:999 /usr/local/lsws/conf -R

COPY wwwroot-default/. /usr/src/wwwroot-default/
COPY maintenance/. /usr/src/maintenance/
RUN mkdir -p /var/www/vhosts/site-local/wwwroot/; \
    mkdir -p /home/LogFiles; \
    chown nobody:nogroup /usr/src/maintenance/ -R; \
    chown nobody:nogroup /var/www/vhosts/site-local; \
    chown nobody:nogroup /var/www/vhosts/site-local/ -R; \
    chown nobody:nogroup /usr/src/wwwroot-default/ -R

RUN ln -sf /dev/stderr /usr/local/lsws/logs/access.log; \
    ln -sf /dev/stderr /usr/local/lsws/logs/error.log; \
    ln -sf /dev/stderr /usr/local/lsws/logs/lsrestart.log; \
    ln -sf /dev/stderr /usr/local/lsws/logs/stderr.log;

VOLUME /home

EXPOSE 2222 80 7080

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance

WORKDIR /var/www/vhosts/site-local/wwwroot

COPY php-container-version /etc
COPY init-php-env.sh /usr/local/bin/
COPY php-entrypoint.sh /usr/local/bin/
COPY sync-now.sh /usr/local/bin/
COPY clean-sync.sh /usr/local/bin/
RUN chmod 444 /etc/php-container-version; \
	chmod +x /usr/local/bin/sync-now.sh; \
	chmod +x /usr/local/bin/clean-sync.sh; \
	chmod +x /usr/local/bin/init-php-env.sh; \
	chmod +x /usr/local/bin/php-entrypoint.sh; \
    ln -s /usr/local/bin/init-php-env.sh /usr/local/bin/init-php-env; \
    ln -s /usr/local/bin/sync-now.sh /usr/local/bin/sync-now; \
    ln -s /usr/local/bin/clean-sync.sh /usr/local/bin/clean-sync

ENTRYPOINT ["php-entrypoint.sh"]
CMD ["/entrypoint.sh"]