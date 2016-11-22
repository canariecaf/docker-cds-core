#!/usr/bin/env bash
set -u 
set -e 
set -x

# Source the build variables of the container so we can be abstracted
CDS_WAYFCURRENTFILENAME="";

. /root/env


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

envsubst < ${origin} > ${target}

}

# this will imprint the docker container with our desired settings

# Preconditions:  the fetch of the code base and it's unzip

# There may be overrides of a certain nature that will change how the container functions
cd ${CDS_BASE}

if [ "${CDS_WAYFCURRENTFILENAME:-NOFILE}" = "NOFILE" ]
then
        CDS_WAYFCURRENTFILENAME=${CDS_WAYFORIGINFILENAME}
fi


#move actual DS php executable to our legacy location
        if [ -a "${CDS_HTMLROOTDIR}/${CDS_WAYFCURRENTFILENAME}" ] && [ "${CDS_WAYFCURRENTFILENAME}" != "${CDS_WAYFDESTFILENAME}" ]
                then
                        mv ${CDS_HTMLROOTDIR}/${CDS_WAYFORIGINFILENAME} ${CDS_HTMLROOTDIR}/${CDS_WAYFDESTFILENAME}
                        echo "CDS_WAYFCURRENTFILENAME=${CDS_WAYFDESTFILENAME}" >> ${CDS_BUILD_ENV}
     					NOW=`date`
        				echo "# ${NOW}" >> ${CDS_BUILD_ENV}
        else
        				
                        echo "${CDS_WAYFDESTFILENAME} destination name is the same ( ${CDS_WAYFCURRENTFILENAME}) or files does not exist, skipping this step"
        fi



cp ${CDS_BASE_TEMPLATE}/config.dist.php.template ${CDS_HTMLROOTDIR}/config.php
cp ${CDS_BASE_TEMPLATE}/IDProvider.conf.dist.php.template ${CDS_HTMLROOTDIR}/IDProvider.conf.php
cp ${CDS_BASE_TEMPLATE}/index.php.template /var/www/html/index.php
chown -R www-data:www-data /var/www/html

esb ${CDS_BASE_TEMPLATE}/ds.conf.template /etc/apache2/conf-available/ds.conf

