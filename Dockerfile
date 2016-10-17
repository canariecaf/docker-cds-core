FROM ubuntu:14.04
MAINTAINER Chris Phillips <chris.phillips@canarie.ca>

USER root
###
### Configure our 'base'
###

### 
### important build arguements
###

ARG CDS_AGGREGATE=https://caf-shib2ops.ca/CoreServices/caf_metadata_signed_sha256.xml
ARG CDS_HTMLROOTDIR=/var/www/html
ARG CDS_HTMLWAYFDIR=/var/www/html/DS
ARG CDS_WAYFDESTFILENAME=CAF.ds
ARG CDS_REFRESHFREQINMIN=5

###
### important environment variables for runtime
###

ENV CDS_AGGREGATE=$CDS_AGGREGATE
ENV CDS_REFRESHFREQINMIN=$CDS_REFRESHFREQINMIN


# inspired from https://github.com/eugeneware/docker-apache-php/blob/master/Dockerfile
# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl


# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install  \
apache2 \
curl \
cron \
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
ADD ./ds/supervisord.conf /etc/supervisor/supervisord.conf

###
### overlay out base application layer from our code repository from github (in this case it's a PHP app)
###

# expecting to be in /var/www/html
WORKDIR  ${CDS_HTMLROOTDIR}

# we want to grab the latest all the time so want to use cache busting
# inspired by: http://stackoverflow.com/questions/37208027/openshift-3-1-prevent-docker-from-caching-curl-resource

RUN (CACHEBUST=$(date +%s); curl -sSLOk https://github.com/canariecaf/cds/archive/master.zip)
RUN unzip master.zip

####
#### Begin Customization of the application layer
####

# move DS into a legacy location 
RUN mv cds-master DS

#move actual DS php executable to our legacy location
RUN mv ${CDS_HTMLWAYFDIR}/WAYF ${CDS_HTMLWAYFDIR}/${CDS_WAYFDESTFILENAME}


# Apply our overlay to the application

COPY ds/config.dist.php.template ${CDS_HTMLWAYFDIR}/config.php
COPY ds/IDProvider.conf.dist.php.template ${CDS_HTMLWAYFDIR}/IDProvider.conf.php

# remove the default index.html file
RUN rm ${CDS_HTMLROOTDIR}/index.html

# place redirection into the root of the webserver
COPY ds/index.php.template ${CDS_HTMLROOTDIR}/index.php


COPY ds/ds.conf /etc/apache2/conf-available/ds.conf
RUN a2enconf ds
#RUN service apache2 reload

# test the environments
RUN echo "${CDS_AGGREGATE}" > /var/www/aggregate2fetch

COPY ds/mdfetch /var/www/mdfetch
RUN chmod +x /var/www/mdfetch

#RUN (cd /var/www; /var/www/mdfetch)

RUN chown -R www-data:www-data ${CDS_HTMLWAYFDIR}

# test crons added via crontab
RUN echo "*/${CDS_REFRESHFREQINMIN} * * * * /var/www/mdfetch " | crontab -  

# RUN echo "*/1 * * * * uptime >> /var/www/html/index.html" | crontab -  
# RUN (crontab -l ; echo "*/2 * * * * free >> /var/www/html/index.html") 2>&1 | crontab -


EXPOSE 80


# Initialization Startup Script
ADD ./ds/start.sh /start.sh
RUN chmod 755 /start.sh

CMD ["/bin/bash", "/start.sh", "${CDS_AGGREGATE}"]

#CMD /bin/bash /start.sh ${CDS_AGGREGATE}



