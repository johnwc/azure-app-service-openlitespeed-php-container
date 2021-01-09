docker build . -t johnwcarew/azure-app-service-openlitespeed-php:latest
docker build . --build-arg PHP_VERSION=lsphp74 -t johnwcarew/azure-app-service-openlitespeed-php:1.6.18-lsphp74
docker build . --build-arg PHP_VERSION=lsphp73 -t johnwcarew/azure-app-service-openlitespeed-php:1.6.18-lsphp73