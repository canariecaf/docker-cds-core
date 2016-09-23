#!/usr/bin/env bash
set -x
set -e 
set -u 

# start all the services
# boostrap the metadata for the code
(cd /var/www; /var/www/mdfetch)
echo "launching supervisord"
/usr/local/bin/supervisord -n