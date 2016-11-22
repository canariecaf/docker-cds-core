FROM ubuntu:14.04
MAINTAINER Chris Phillips <chris.phillips@canarie.ca>


USER root

# docker automated builds choked strangely after working intitially.
# the next uncommented line was inspired by: 
# http://stackoverflow.com/questions/28517090/docker-hub-automated-build-fails-but-locally-not
# and
# http://stackoverflow.com/questions/28649793/different-home-directory-during-docker-build-in-docker-hub
ENV HOME /root

###
### Configure our 'base'
###
ARG CDS_BASE=/root/cds
ARG CDS_BASE_TEMPLATE=${CDS_BASE}/template

# where we leave our settings inside the container for everything else to inherit and use

ENV CDS_BUILD_ENV=/root/env

### 
### important build arguements
###


ARG CDS_AGGREGATE=https://caf-shib2ops.ca/CoreServices/caf_metadata_signed_sha256.xml
ARG CDS_CODEBASE=/var/www/cds
ARG CDS_HTMLROOTDIR=${CDS_BASE}/html
ARG CDS_HTMLWAYFDIR=DS
ARG CDS_WAYFORIGINFILENAME=WAYF
ARG CDS_WAYFDESTFILENAME=CAF.ds
ARG CDS_REFRESHFREQINMIN=5
ARG CDS_OVERLAYURL=""

###
### important environment variables for runtime
###

ENV CDS_BASE=$CDS_BASE
ENV CDS_CODEBASE=$CDS_CODEBASE
ENV CDS_AGGREGATE=$CDS_AGGREGATE
ENV CDS_REFRESHFREQINMIN=$CDS_REFRESHFREQINMIN
ENV CDS_OVERLAYURL=$CDS_OVERLAYURL
ENV CDS_WAYFORIGINFILENAME=$CDS_WAYFORIGINFILENAME



# inspired from https://github.com/eugeneware/docker-apache-php/blob/master/Dockerfile
# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl


# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install  \
apache2 \
curl \
cron \
gettext-base \
libapache2-mod-php5 \
php-apc \
python-setuptools \
supervisor \
unzip \
vim-tiny && \
    rm -rf /var/lib/apt/lists/*


# apache config
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
RUN chown -R www-data:www-data /var/www/

RUN mkdir -p /var/lock/apache2 /var/run/apache2 

# php config
# adjustments below are for PHP to be able to handler 'larger things' -- but we want slim, so commented out
#RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/apache2/php.ini
#RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
COPY ./ds/supervisord.conf /etc/supervisor/supervisord.conf

###
### overlay out base application layer from our code repository from github (in this case it's a PHP app)
###


WORKDIR  ${CDS_BASE}

#
# writing our settings to the image for other scripts to leverage

RUN echo "CDS_AGGREGATE=${CDS_AGGREGATE}" > ${CDS_BUILD_ENV}
RUN echo "CDS_BASE=${CDS_BASE}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_BASE_TEMPLATE=${CDS_BASE_TEMPLATE}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_CODEBASE=${CDS_CODEBASE}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_HTMLROOTDIR=${CDS_HTMLROOTDIR}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_HTMLWAYFDIR=${CDS_HTMLWAYFDIR}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_OVERLAYURL=${CDS_OVERLAYURL}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_REFRESHFREQINMIN=${CDS_REFRESHFREQINMIN}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_WAYFDESTFILENAME=${CDS_WAYFDESTFILENAME}" >> ${CDS_BUILD_ENV}
RUN echo "CDS_WAYFORIGINFILENAME=${CDS_WAYFORIGINFILENAME}" >> ${CDS_BUILD_ENV}
RUN chmod 755 /root/env
RUN chmod 755 /root


# we want to grab the latest all the time so want to use cache busting
# inspired by: http://stackoverflow.com/questions/37208027/openshift-3-1-prevent-docker-from-caching-curl-resource

RUN (CACHEBUST=$(date +%s); curl -sSLOk https://github.com/canariecaf/cds/archive/master.zip)
RUN unzip master.zip
RUN mv cds-master ${CDS_BASE}/html

# remove the default index.html file
RUN rm /var/www/html/index.html

####
#### Begin Customization of the application layer
####

# First we copy our known templates into place:

RUN mkdir -p ${CDS_BASE}/template/
COPY ds/*.template ${CDS_BASE}/template/


# test crons added via crontab
RUN echo "*/${CDS_REFRESHFREQINMIN} * * * * ${CDS_BASE}/mdfetch " | crontab -  


# NOTE:  the imprinting of the WAYF software is done  with this command.
# if you want to imprint it DIFFERENTLY, write the ENV file and THEN invoke this again
# 
COPY ds/imprint.sh ${CDS_BASE}/imprint.sh
RUN chmod +x ${CDS_BASE}/imprint.sh
RUN ${CDS_BASE}/imprint.sh

COPY ds/mdfetch ${CDS_BASE}/mdfetch
RUN chmod +x ${CDS_BASE}/mdfetch
RUN chown -R www-data:www-data ${CDS_HTMLROOTDIR}/
RUN chmod 755 /root/cds


RUN a2enconf ds


#
# place the overlay harness into image, the overlay URL to use, and invoke
# default is to be a blank overlay URL and 'do nothing'

COPY ds/overlay.sh ${CDS_BASE}/overlay.sh
RUN chmod +x ${CDS_BASE}/overlay.sh


RUN (cd ${CDS_BASE}; ${CDS_BASE}/overlay.sh ${CDS_OVERLAYURL} )


EXPOSE 80
EXPOSE 443

# Initialization Startup Script
# 
# This was 'ADD', using COPY instead to fix breaking build inspired by responses here:
# http://stackoverflow.com/questions/24958140/what-is-the-difference-between-the-copy-and-add-commands-in-a-dockerfile
COPY ./ds/start.sh /root/start.sh
RUN chmod 755 /root/start.sh

CMD ["/bin/bash", "/root/start.sh", "${CDS_AGGREGATE}"]




