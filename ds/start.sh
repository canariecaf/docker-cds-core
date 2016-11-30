#!/usr/bin/env bash
set -x
set -e 
set -u 




function isGoodURL ()
{
	# 0 is 'good' or true since this maps to a command that successfully ran with zero errors
	# 1 is 'bad' or false since it maps to a command that errored out
	# see: http://stackoverflow.com/questions/5431909/bash-functions-return-boolean-to-be-used-in-if

	local regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
	local theURL=""

	if [ -z "$1" ]                           # Is parameter #1 zero length?
   	then
     	echo "Parameter #1 is zero length, invalid invocation"  # Or no parameter passed.
     	return 1
 	else
 		theURL=$1
 	fi
	
	if [[ $theURL =~ $regex ]]
	then 
	
		return 0

	else
    	echo "Nope, $theURL is not a url"
    	return 1
	fi

}



if [ $# -eq 0 ]
  then
    echo "No arguments supplied, default aggregate to come from /root/env"
else
    echo "Detected command line aggregate of:${1} . Once validated, using it by tacking it on the end of our env"
		if isGoodURL ${1} 
		then 
		    echo "# Overriding the CDS_AGGREGATE"
			echo "CDS_AGGREGATE=${1}" >> /root/env
			echo "Since aggregate is new, we redo our flip CDS_TRIGGER_IMPRINT from ${CDS_TRIGGER_IMPRINT}"
			CDS_TRIGGER_IMPRINT=${CDS_TRIGGER_IMPRINT}
			echo "To CDS_TRIGGER_IMPRINT: ${CDS_TRIGGER_IMPRINT}"
			
		else
		    echo "Passed in aggregate invalid, IT IS NOT APPLIED. Using /root/env as is."
		fi

fi

if [ "${CDS_TRIGGER_IMPRINT}" = "Y" ]
then
	echo "Imprinting image with new settings for container"
	(cd ${CDS_BASE}; ${CDS_BASE}/imprint.sh)
else
	echo "Container existing settings being used, imprinting being skipped"
fi



# we do this again as we may have self updated it above.
. /root/env


if isGoodURL $CDS_AGGREGATE 
then 
	# note that the metadata fetch needs to have the config file as the full path.
	# mdfetch needs to know what directory to write to and is derived from within the container

	(cd ${CDS_BASE}; ${CDS_BASE}/mdfetch)
else
    echo "aggregate invalid, skipping update"
fi

echo "launching supervisord"
/usr/local/bin/supervisord -n