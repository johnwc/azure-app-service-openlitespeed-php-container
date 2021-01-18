#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

set -e

if ! [ -z ${WEBSITE_SITE_NAME+x} ]; then
	echo -e >&2 "${RED}Disabled LiteSpeed Web Admin.${NC}"
	touch /usr/local/lsws/conf/disablewebconsole
fi

if ! [ -d /home/LogFiles/site-local ]; then
	mkdir -p /home/LogFiles/site-local
	chown nobody:nogroup /home/LogFiles/site-local
	chmod 774 /home/LogFiles/site-local
fi
if ! [ -d /home/site/wwwroot ]; then
	mkdir -p /home/site/wwwroot
	chown nobody:nogroup /home/site
	chmod 774 /home/site
fi

if ! [ -f /etc/osync/sync.conf ]; then
	if [ -f /home/site/sync.conf ]; then
		echo -e >&2 "${GREEN}Copying sync.conf to /etc/osync/.${NC}"
		cp -a /home/site/sync.conf /etc/osync/
	else
		echo -e >&2 "${GREEN}Copying default sync.conf to /etc/osync/.${NC}"
		cp -a /usr/src/php/sync.conf /etc/osync/
	fi
fi

if [ -z ${PHP_CRON+x} ]; then
	export PHP_CRON='*/10 * * * *'
fi

cat >/etc/cron.d/phpcron <<EOL 
${PHP_CRON} root date > /home/site/cron-last-run; cd /home/site/; if [ -e cron.sh ]; then /home/site/cron.sh > /home/site/cron.log 2>&1; fi
EOL

chmod 600 /etc/cron.d/php
chmod 600 /etc/cron.d/phpcron

if [ ! -e /var/www/vhosts/site-local/.osync_workdir/state ] && [ -e /home/site/.osync_workdir/state ]; then
	echo -e >&2 "${ORANGE}Cleaning sync state from site.${NC}"
	rm -rf /home/site/.osync_workdir/state
fi

echo -e >&2 "${GREEN}Monitoring .htaccess changes.${NC}"
(while read line; do if [ "$line" == ".htaccess" ]; then sleep 5; echo -e "${ORANGE}$line modified, gracefully restarting litespeed${NC}"; /usr/local/lsws/bin/lswsctrl try-restart; fi; done < <(inotifywait -m -e modify -e move -e create -e delete --format "%f" "/var/www/vhosts/site-local/wwwroot/")) &

SYNC_MAIN="/usr/src/maintenance/sync_maintenance.html"
if [ -f /home/site/sync_maintenance.html ]; then
	echo -e >&2 "${ORANGE}Using custom sync maintenance page.${NC}"
	SYNC_MAIN="/home/site/sync_maintenance.html"
fi

if ! [ "$(ls -A /var/www/vhosts/site-local/wwwroot/)" ]; then
	if ! [ "$(ls -A /home/site/wwwroot/)" ]; then
		echo -e >&2 "${GREEN}Initiating default OoB site.${NC}"
		cp -a /usr/src/wwwroot-default/. /home/site/wwwroot/
		sync-now &
	else
		echo -e >&2 "${GREEN}Syncing site to local-site.${NC}"
		(
		clean-sync;
		sync-now) &
	fi
else
	echo -e >&2 "${GREEN}Existing files in site-local.${NC}"
	ls -A /var/www/vhosts/site-local/wwwroot/
	sync-now &
fi
