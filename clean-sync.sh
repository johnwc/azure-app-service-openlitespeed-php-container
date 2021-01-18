#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

SYNC_MAIN="/usr/src/maintenance/sync_maintenance.html"
if [ -f /home/site/sync_maintenance.html ]; then
	echo -e >&2 "${ORANGE}Using custom sync maintenance page.${NC}"
	SYNC_MAIN="/home/site/sync_maintenance.html"
fi

HAS_HTACCESS=
if [ -f /home/site/wwwroot/.htaccess ]; then
	export HAS_HTACCESS='1'
fi

shopt -s dotglob
rm -rf /home/site/.osync_workdir
rm -rf /var/www/vhosts/site-local/.osync_workdir
rm -rf /var/www/vhosts/site-local/wwwroot/*
shopt -u dotglob

cp /usr/src/maintenance/.htaccess /var/www/vhosts/site-local/wwwroot/
cp "$SYNC_MAIN" /var/www/vhosts/site-local/wwwroot/

rsync -ar --exclude='/.htaccess' /home/site/wwwroot/ /var/www/vhosts/site-local/wwwroot/

if ! [ -z "$HAS_HTACCESS" ]; then
	cp -a /home/site/wwwroot/.htaccess /var/www/vhosts/site-local/wwwroot/
else
	rm -f /var/www/vhosts/site-local/wwwroot/.htaccess
fi

rm -f /var/www/vhosts/site-local/wwwroot/sync_maintenance.html
