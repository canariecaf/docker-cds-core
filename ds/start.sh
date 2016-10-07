#!/usr/bin/env bash
set -x
set -e 
set -u 

# start all the services
# boostrap the metadata by fetching if from /var/www/aggregate2fetch which should be a URL for an XML file
MYAGGREGATE=/var/www/aggregate2fetch
if [ $# -eq 0 ]
  then
  	AGGDEFAULT=`cat ${MYAGGREGATE}`
    echo "No arguments supplied, default aggregate from /var/www/aggregate2fetch is: ${AGGDEFAULT}"
else
    echo "Detected ${1} as aggregate, storing this for our cronjob to use in our container in /var/www/aggregate2fetch"
	echo "${1}" > ${MYAGGREGATE}
fi


(cd /var/www; /var/www/mdfetch)
echo "launching supervisord"
/usr/local/bin/supervisord -n