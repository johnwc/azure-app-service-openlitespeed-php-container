# PHP on Azure App Service for Containers using OpenLiteSpeed
[![docker pulls](https://img.shields.io/docker/pulls/johnwcarew/azure-app-service-openlitespeed-php?style=flat&color=blue)](https://hub.docker.com/r/johnwcarew/azure-app-service-openlitespeed-php)

This repository contains Docker images for PHP running on Azure App Service Linux container using OpenLiteSpeed web server.

## Image Repository
https://hub.docker.com/r/johnwcarew/azure-app-service-openlitespeed-php

## Known issues
Because FTP transactions are handled outside of the container to the durable storage, updates from FTP does not trigger file change notification for synchronization service. After making updates from FTP and you want those changes put in place immediately, you will need to SSH to the container and run `sync-now` to initiate a immediate synchronization. Otherwise, the synchronization service will pick up the changes the next time the sync service's wait time expires, which defaults to every two hours.

## Build Components

| Component     | Version      |
| ------------- | ------------ |
| Linux         | Ubuntu 18.04 |
| OpenLiteSpeed | 1.6.18       |
| PHP           | 7.4          |

* SSH has been enabled on port 2222 to be able to SSH to the container in Azure App Service.
* A cron/scheduled task is setup to run `/home/site/cron.sh`, if it exists, every 10 minutes. Set `PHP_CRON` environment variable to a valid [cron formated](https://en.wikipedia.org/wiki/Cron) schedule to change from the default execute interval. The last `cron.sh` task run is logged to `/home/site/cron.log`

## Container storage for site

With the update to v1.2 of this container, the web server now serves the site from a local copy of the site that is synchronized from the durable storage. The container runs a synchronization service that will synchronize the `/home/site/` with `/var/www/vhosts/site-local/` bidirectionally. It monitors the `/home/site` directory for changes, if it detects changes it runs the synchronization. If it does not detect any changes, it will run a synchronization every two hours.

### Commands

These are supported commands that you can manually execute from the Azure App Service's SSH shell.

* `sync-now` - Start a synchronization task immediately.
* `clean-sync` - Initiates a fresh clean copy from durable to local
  * Clears out local site's wwwroot directory 
  * Clears folder's synchronization state
  * Copies sync maintenance template to local site
  * Copies site content from `/home/site/wwwroot` to `/var/www/vhosts/site-local/wwwroot`

### Maintenance template

When a fresh container is deployed or a container is regenerated from an updated docker image, the initial local site's wwwroot directory is empty. To minimize showing a *404* or *500* error while the site copies from durable to local storage, a `sync_maintenance.html` template file is copied to the root of the local site. If this file and the maintenance `.htaccess` exists, it will always be displayed to any browser accessing the site.

#### Custom maintenance template

You can place a `sync_maintenance.html` file with your own custom HTML within the `/home/site` directory in the durable storage. This would be the `/site` directory if uploading from FTP.

## Deployment

### ARM Template
A sample Azure arm template is available in the [github repo](https://github.com/johnwc/azure-app-service-openlitespeed-php-container/blob/master/infra.arm.json). 

* The app plan must be an Azure App Service Linux plan.