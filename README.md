#						SNMP check


##  What is it?
##  -----------
Project for checking snmp and get the results in csv 


##  The Latest Version

	version 1.1 2016.03.04
	
### There are realised:
- add/edit/remove user form/table
- login form
- password change form
- add/edit/remove snmpworkers form/table 
- add ntpcheck task form (with dummy worker) and start task
- add/remove/show tasks table. task monitoring, task status/progress/warning update, message system between tasks level and workers.
- html templates
- dummy worker


### What not yet ready:
- autentification do not used 
- not crontab task starting ( task start only from 'add task' page now ), but prepared hook for it.
- do not test real workers
- do not collect ip yet ( from pgsql, only from existing group ) 


### What technology used:

- perl with modules:
-- use DBI;
-- use HTML::Template;
-- use CGI qw(param);
-- use Digest::SHA qw(sha1 sha1_hex );
-- use JSON;
-- use HTML::Entities;

- db 
-- sqlite

- messages between workers and task level
-- json


## Installation

Install by root ( or by local user, but don't forget add path to scripts BEGIN section ) the next modules into perl:
```
# perl  -MCPAN -e shell
install HTML::Template
install DBI
install DBD::SQLite
install JSON
install HTML::Entities
```

Extract the tar archive to /opt/snmpckeck :
```
# gunzip snmpcheck.tar.gz
# tar -C /opt snmpcheck.tar
```
Set the owner
```
# chown -R SomeUser:SomeGroup /opt/snmpckeck
```
Start your httpd server with html-home: /opt/snmpckeck/html and cgi-bin: /opt/snmpckeck/html/cgi-bin .





  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

	
