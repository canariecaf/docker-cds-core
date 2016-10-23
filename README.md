## A Central Discovery Service 

A [Docker](http://docker.com) image for an 'as is' base of the  [v1.20.2 SWITCHwayf](https://forge.switch.ch/projects/wayf) built on Ubuntu 14.04.

This image uses Supervisord the daemon to allow 2 processes to run

- apache2
- a cron daemon

The image is purposely configured clean with an simple configuration for SWITCHwayf with options to permit derivations to choose what they customize.


## To Build the image

### The variables & their defaults

Environment variables with their defaults if they do not exist are:
- CDS_AGGREGATE - the aggregate to point at and ingest via the cron command
	-- defaults to: https://caf-shib2ops.ca/CoreServices/caf_metadata_signed_sha256.xml
- CDS_HTMLROOTDIR - the HTML root directory of the webserver
	-- defaults to: /var/www/html
- CDS_HTMLWAYFDIR - the location in the container where the DS lives
	-- default to: /var/www/html/DS
- CDS_WAYFDESTFILENAME - the actual WAYF file to invoke
	-- defaults to: CAF.ds
- CDS_OVERLAYURL - The zip file in URI format to retrieve (note you can use file:/// to refer to a local zip)
	-- defaults to: <blank>

## Runtime overrides of this image
- CDS_AGGREGATE - the aggregate to point at and ingest via the cron command
	-- defaults to: https://caf-shib2ops.ca/CoreServices/caf_metadata_signed_sha256.xml
- CDS_REFRESHFREQINMIN - # of minutes between cron'd processing of the aggregate after intial fetch on start
	-- defaults to: 5 


pass them in on the command line:

```sh
$ sudo docker run -e CDS_AGGREGATE=http://md.example.com/somethings.xml -e CDS_REFRESHFREQINMIN=5 -d -p 80:80 --restart=always canariecaf/docker-cds-core
```

## How to do a basic test?

Open browser and point to: **http://localhost**
If everthing is fine you should see the default Service Discovery Page with your aggregate