#!/bin/bash
cat >/etc/motd <<EOL 
   _____                               
  /  _  \ __________ _________   ____  
 /  /_\  \\___   /  |  \_  __ \_/ __ \ 
/    |    \/    /|  |  /|  | \/\  ___/ 
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/ 
A P P   S E R V I C E   O N   L I N U X
Documentation: http://aka.ms/webapp-linux
PHP quickstart: https://aka.ms/php-qs
Container Version : `cat /etc/php-container-version`
PHP version : `php -v | head -n 1 | cut -d ' ' -f 2`
#################################################

EOL
cat /etc/motd

if [ -z ${PHP_CRON+x} ]; then
	export PHP_CRON='*/10 * * * *'
fi

cat >/etc/cron.d/phpcron <<EOL 
${PHP_CRON} root cd /home/site/; if [ -e cron.sh ]; then /home/site/cron.sh > /home/site/cron.log 2>&1; fi; date > /home/site/cron-last-run
EOL
chmod 600 /etc/cron.d/php
chmod 600 /etc/cron.d/phpcron

service ssh start
service cron start

exec "$@"