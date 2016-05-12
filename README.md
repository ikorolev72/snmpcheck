#						SNMP check


##  What is it?
##  -----------
Web based frontend and sheduling ( once and periodicly ) background tasks for snmp-requests to devices iPasolink and get the results in csv. 



##  The Latest Version

	version 1.7 2016.05.12

### What new
- crontab tasks 
- add/remove/show crontab table
- workers multi threads ( Parallel run ) 
- save default forms parameters 
	
### There are realised:
- add/edit/remove user form/table
- login form
- password change form
- add/edit/remove snmpworkers form/table 
- add/remove/show tasks table. task monitoring, task status/progress/warning update, message system between tasks level and workers.
- html templates
- all workers
- all frontends forms
- command line tool 'task starter', 'task updater' 
- authorisation. Login-logout, check on pages if required.
- real workers tested
- test collection IPs from pgsql
- logging of user actions
- crontab tasks
- add/remove/show crontab table.
- worker threads 


### What technology used:

 perl with modules:  
 - use DBI;
 - use HTML::Template;
 - use CGI qw(param);
 - use Digest::SHA qw(sha1 sha1_hex );
 - use JSON;
 - use JSON::XS;
 - use HTML::Entities;
 - use threads;

 db  
 - sqlite

 messages between workers and task level  
 - json


## Installation

Install by root ( or by local user, but don't forget add path to scripts BEGIN section ) the next modules into perl:
```
# perl  -MCPAN -e shell
install HTML::Template
install DBI
install DBD::SQLite
install JSON
install JSON::XS
install HTML::Entities
install threads
```

Make the preffered directory for your installation, for example /opt/snmpcheck
Extract the tar archive to /opt/snmpcheck :
```
$ mkdir /opt/snmpcheck
$ gunzip snmpcheck.tar.gz
$ tar -C /opt/snmpcheck -xf snmpcheck.tar
```

Add next lines into crontab of your user by command `crontab -e` :
```
*       *       *       *       *       /opt/snmpcheck/tools/task_starter.pl >> /opt/snmpcheck/data/log/crontab.log 2>&1
*       *       *       *       *       /opt/snmpcheck/tools/cron_starter.pl >> /opt/snmpcheck/data/log/crontab.log 2>&1
```
If you will use another path you may faced with `Can't locate COMMON_ENV.pm in @INC` error. In such case you can add new path 
in files task_starter.pl and cron_starter.pl, or add lines in crontab with path to 
library, like `* * * * * /usr/bin/perl -I /SOME/PATH/lib /SOME/PATH/tools/task_starter.pl >> /SOME/PATH/data/log/crontab.log 2>&1`
 

Start your httpd server with html-home: /opt/snmpckeck/html and cgi-bin: /opt/snmpckeck/html/cgi-bin .


  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

	
