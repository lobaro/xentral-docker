#!/bin/sh

set -e

# start the cron deamon
service cron start
service cron status

exec "$@"