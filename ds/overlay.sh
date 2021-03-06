#!/usr/bin/env bash
set -u 
set -e 
set -x

# Source the build variables of the container so we can be abstracted
. /root/env


# set up the overlay environment for this harness to invoke the overlay steps
#
OVLDEFAULT="";
MYOVERLAY="${CDS_OVERLAYURL}"
WORKDIR="${CDS_BASE}/_work"


# Note that you can use file:///path/to/source/file as the default 
# but you need to place it in the appropriate location (in the image) to be copied into place before this runs

if [ $# -eq 0 ]
  then
    OVLDEFAULT=${MYOVERLAY}
    echo "No arguments supplied, no overlay actions taken, exiting overlay process gracefully"
    exit
fi

# If you reach this stage, you have a URL retrieved from on disk in the image and are about to:
# fetch it
# create a work directory
# unzip it
# invoke the overlay command 'do_overlay.sh'


mkdir ${WORKDIR}

OVERLAY=${1:-$OVLDEFAULT}
OVLPACK=`echo "${OVERLAY##*/}"`

(cd ${WORKDIR}; curl  -vsSLOk  ${OVERLAY} -o ${OVLPACK})
(ls -la; cd ${WORKDIR}; ls -la ; unzip ./${OVLPACK} )

# do the 'act of overlaying' by requiring the assets folder.
ASSETROOT=`find ${WORKDIR} -name "assets"`

(cd ${ASSETROOT}/..; ./do_overlay.sh)

echo "Overlay complete."
exit
