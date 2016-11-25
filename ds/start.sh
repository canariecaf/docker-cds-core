#!/usr/bin/env bash
set -x
set -e 
set -u 


# start all the services
# boostrap the metadata by fetching if from /var/www/aggregate2fetch which should be a URL for an XML file
. /root/env

MYAGGREGATE=${CDS_AGGREGATE}

if [ "${CDS_TRIGGER_IMPRINT}" = "Y" ]
then
	echo "Imprinting image with new settings for container"
	(cd ${CDS_BASE}; ${CDS_BASE}/imprint.sh)
else
	echo "Container existing settings being used, imprinting being skipped"
fi


if [ $# -eq 0 ]
  then
  	AGGDEFAULT=${CDS_AGGREGATE}
    echo "No arguments supplied, default aggregate  is: ${AGGDEFAULT}"
else
    echo "Detected ${1} as aggregate, using this for our aggregate by tacking it on the end of our env"
    echo "# Overriding the CDS_AGGREGATE"
	echo "CDS_AGGREGATE=${1}" >> /root/env
fi


. /root/env

regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

if [[ $CDS_AGGREGATE =~ $regex ]]
then 
	
	#
	# note that the metadata fetch needs to have the config file as the full path.
	# mdfetch needs to know what directory to write to and is derived from within the container

	(cd ${CDS_BASE}; ${CDS_BASE}/mdfetch)


else
    echo "aggregate invalid, skipping update"
fi

echo "launching supervisord"
/usr/local/bin/supervisord -n