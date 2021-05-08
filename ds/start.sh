#!/usr/bin/env bash

#   This script starts the supervisor daemon for httpd and cron
#
####################
# Step 1: set base operational posture
####################

set -e 
# the name of the script, avoiding symlinks
myname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# The 'debug' settings are done first to allow the script to supercede local settings
[[  "${CDS_DEVELOPMENTMODE}" = "true" ]] && set -x ||  echo "INFO:$myname: running"

####################
# Step 2: Create our necessary functions
####################
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
#
# function overrideFromEnv (varname)
#   varname - variable to pluck from container environment (passed in from settings) and persist in /root/env

function overrideFromEnv ()
{
	local varname=$1
#	local varval=`eval \$$1`
if [[ -z "${!varname}" ]]
then
 	echo "$varname is empty, no override done"
 	else
 	 CDS_TRIGGER_IMPRINT="Y"
 	 echo "$varname=${!varname}" >> /root/env 
fi

}

####################
# Step 3: These are the PERMITTED runtime overrides we will inherit
####################
overrideFromEnv CDS_REFRESHFREQMIN
overrideFromEnv CDS_HTMLWAYFDIR
overrideFromEnv CDS_WAYFDESTFILENAME

# only override if 
if isGoodURL ${CDS_AGGREGATE} 
then 
    echo "# Overriding the CDS_AGGREGATE"
	overrideFromEnv CDS_AGGREGATE
	echo "Since aggregate is new, we redo our flip CDS_TRIGGER_IMPRINT from ${CDS_TRIGGER_IMPRINT}"
	CDS_TRIGGER_IMPRINT="Y"
	echo "To CDS_TRIGGER_IMPRINT: ${CDS_TRIGGER_IMPRINT}"
	
else
    echo "Passed in aggregate empty or invalid URL, NOT APPLIED. Using /root/env as is."
fi

####################
# Step 4: Given settings, detect if we need to 're-bake' the image
####################

if [ "${CDS_TRIGGER_IMPRINT}" = "Y" ]
then
	echo "Imprinting image with new settings for container"
	(cd ${CDS_BASE}; ${CDS_BASE}/imprint.sh)
else
	echo "Container existing settings being used, imprinting being skipped"
fi

####################
# Step 5: Load our environment - post 'bake'
####################

# we do this again as we may have self updated it above.
. /root/env

####################
# Step 6: Process the aggregate
####################

if isGoodURL $CDS_AGGREGATE 
then 
	# note that the metadata fetch needs to have the config file as the full path.
	# mdfetch needs to know what directory to write to and is derived from within the container

	(cd ${CDS_BASE}; ${CDS_BASE}/mdfetch)
else
    echo "aggregate invalid, skipping update"
fi
####################
# Step 6: Launch supervisorD
####################

echo "launching supervisord"
# uncomment sleep to permit yourself to spawn a shell for diagnosis
#sleep 10000
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
