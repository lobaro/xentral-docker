#!/bin/sh

set -e

# TODO: if /var/www/html is empty, copy installer and set directory permissions

# start the cron deamon
service cron start
service cron status

php-fpm7.4 -D

echo "starting $@"

exec "$@"