## A Central Discovery Service 

A [Docker](http://docker.com) image for an 'as is' base of the  [v1.20.2 SWITCHwayf](https://forge.switch.ch/projects/wayf) built on Ubuntu 14.04.

This image uses Supervisord the daemon to allow 2 processes to run

- apache2
- a cron daemon


The image is purposely configured clean with an simple configuration for SWITCHwayf with options to permit derivations to choose what they customize.



## To Run the image

### The variables & their defaults

Environment variables with their defaults if they do not exist are:
- CDS_AGGREGATE - the aggregate to point at and ingest via the cron command
-- default  is testshib: http://www.testshib.org/metadata/testshib-providers.xml
- CDS_WORKDIR - the 
- CDS_HTMLROOTDIR - 
- CDS_HTMLWAYFDIR - 

to override them:

pass them in on the command line:

```sh
$ sudo docker run --env <key>=<value>
```




```sh
$ sudo docker run -d -p 80:80 code-clearinghouse/docker-cds-core
```

## How to do a basic test?


Open browser and point to: **http://localhost**

## How to configure this image


Replace /path/to/php/src with your php sources directory.

```sh
$ docker run -d -v /path/to/php/src:/srv -p 80:80 ricardson/docker-caddy-php
```

If everthing is fine you should see the PHP Test Page.