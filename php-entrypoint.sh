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

init-php-env

service ssh start
service cron start
service osync-srv start

exec "$@"