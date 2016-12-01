#!/usr/bin/env bash

#
#   This script imprints the settings either from the environment or /root/env
#   It doesn't do any operational aspects (e.g. restart apache), which should be done after
#
####################
# Step 1: set base operational posture
####################

set -e 
# the name of the script, avoiding symlinks
myname="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# The 'debug' settings are done first to allow the script to supercede local settings
[[  "${CDS_DEVELOPMENTMODE}" = "true" ]] && set -x ||  echo "INFO:$myname: running"

# Source the build variables of the container so we can be abstracted
CDS_WAYFCURRENTFILENAME="";

####################
# Step 2: Load our environment
####################
. /root/env

####################
# Step 3: Create our necessary functions
####################

#
# function esb (origin,target)
#   Description: A harness to allow envsubst to run on arbitrary files along with error trapping
#
#  origin -  the origin file name (usually a template) 
#  target -  the target file to be updated

function esb ()
{


	local origin=""
	local target=""
	if [ -z "$1" ]                           # Is parameter #1 zero length?
   then
     echo "-Parameter #1 is zero length, invalid invocation"  # Or no parameter passed.
 	else
 		origin=$1
 	fi
	
	if [ -z "$2" ]                           # Is parameter #1 zero length?
	   then
	     echo "-Parameter #2 is zero length, invalid invocation"  # Or no parameter passed.
	else
		target=$2
	 fi

(source ${CDS_BUILD_ENV}; export $(cat ${CDS_BUILD_ENV} |egrep -v "^#" |cut -d= -f1); envsubst < ${origin} > ${target} )

}

####################
# Step 4: The Main code being executed
####################
# this will imprint the docker container with our desired settings
# Preconditions:  the fetch of the code base and it's unzip
# There may be overrides of a certain nature that will change how the container functions


cd ${CDS_BASE}

# Step 4.1: process our WAYFCURRENTFILENAME and set the php executable

if [ "${CDS_WAYFCURRENTFILENAME:-NOFILE}" = "NOFILE" ]
then
        CDS_WAYFCURRENTFILENAME=${CDS_WAYFORIGINFILENAME}
fi           

#move actual DS php executable to our legacy location
        if ( [ -a "${CDS_HTMLROOTDIR}/${CDS_WAYFCURRENTFILENAME}" ] && [ -n "${CDS_WAYFDESTFILENAME}" ] && [ "${CDS_WAYFCURRENTFILENAME}" != "${CDS_WAYFDESTFILENAME}" ]  )
                 then
                        mv ${CDS_HTMLROOTDIR}/${CDS_WAYFORIGINFILENAME} ${CDS_HTMLROOTDIR}/${CDS_WAYFDESTFILENAME}
                        echo "CDS_WAYFCURRENTFILENAME=${CDS_WAYFDESTFILENAME}" >> ${CDS_BUILD_ENV}
     					NOW=`date`
        				echo "# ${NOW}" >> ${CDS_BUILD_ENV}
        else
        				
                        echo "${CDS_WAYFDESTFILENAME} destination name is the same ( ${CDS_WAYFCURRENTFILENAME}) or files does not exist, skipping this step"
        fi

# Step 4.2: copy from our templates directory to our operational location

cp ${CDS_BASE_TEMPLATE}/config.dist.php.template ${CDS_HTMLROOTDIR}/config.php
cp ${CDS_BASE_TEMPLATE}/IDProvider.conf.dist.php.template ${CDS_HTMLROOTDIR}/IDProvider.conf.php
cp ${CDS_BASE_TEMPLATE}/index.php.template /var/www/html/index.php
chown -R www-data:www-data /var/www/html

# Step 4.3: copy from our templates directory to our operational location and overlay shell settings

esb ${CDS_BASE_TEMPLATE}/ds.conf.template /etc/apache2/conf-available/ds.conf



