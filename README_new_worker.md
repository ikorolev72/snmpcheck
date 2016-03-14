#						SNMP check. New worker

## How to add new worker

### How does it work

When you click in browser at frontend url, cgi script  show the form using html-tempalate and  with ip, group, 
all_ipasolink (subgroup, inop, ucon, umng ) fields ( deppends of config.ini variable `iplistdb`) and any 
additional fields you need for selected snmp tools.
When you press the button 'Send', script will check a parameters and if all ok and you confirm new task, then add new 
task into tasks table. Now you can see your new task in 'Tasks list' page with 'added' status. 
By crontab special tool ( tool/task_starter.pl) check new added tasks, prepare special JSON file with parameters 
and start worker. The status in 'Tasks list' changes from 'added' to 'started'.
Worker get the parameters from JSON file, prepare IP list and begin runing by all IPs. Worker prepare special JSON
file with status, percent of executed IPs and  descriptions. When you refresh 'Tasks list', the status of task will 
changed to 'running'. When worker finish process of IPs, then task status will change to 'finished' and open the link 
to report file. Now you can download the report file.
If worked failed or frosen by any reason then 'task updater' wait any new JSON files during 1 hour. After it change 
the status of the task to 'failed'.

When worker running:
any logs writing in ($$ - mean task id)
```
data/log/snmpcheck.log
data/log/worker.$$.log
```

JSON input and output files
```
data/json/$$.param.json
data/json/$$.out.json
```
report files:
```
html/report/*_$$_log.csv
```


### Prepare files for new worker.
Go to SNMPCHECK base dir. There are 3 files in skel directory. 
```
$ find data/skel/
data/skel/
data/skel/sample_worker.pl
data/skel/sample_template.htm
data/skel/sample_frontend.cgi
```
For example you need to add new checking tool aaa.
Copy skel files to appropriate dirs with new filenames:
```
cp data/skel/sample_worker.pl worker/aaa_worker.pl
cp data/skel/sample_template.htm data/template/aaa.htm
cp data/skel/sample_frontend.cgi html/cgi-bin/aaa.cgi
chmod +x html/cgi-bin/aaa.cgi worker/aaa_worker.pl
```


By default, frontend cgi-script use html-template file with form and by pressing button get the the next variable:
-	$Param->{ip}
-	$Param->{desc}
-	$Param->{group}
-	$Param->{subgroup}
-	$Param->{all_ipasolink}
-	$Param->{inop}
-	$Param->{ucon}
-	$Param->{umng}
By this variable frontend prepare JSON file for worker. If you need additional data for snmp tools, you can add fields into
template, and handler into frontend and worker for additional data. All parameters will be added into JSON automatically.



### Edit the html template
Edit html-template file if you need add new parameters to your worker. For example in data/skel/sample_template.htm you 
can see the variable sample_variable.


### Edit the frontend file
Add the new name 'aaa' to variable approved_application_for_no_authentication or approved_application_for_authentication in your config.ini file.
```approved_application_for_authentication=ntp,tzauth,aaa```

Open file html/cgi-bin/aaa.cgi with any editor and edit the strings in comments string 'CHANGE_ME'. For example:
  ##############################################
  ########### CHANGE_ME
$sname="aaa";   # see approved_application_for_no_authentication and approved_application_for_authentication in config.ini
$template = HTML::Template->new(filename => 'aaa.htm', die_on_bad_params=>0 );
$title="AAA Application";
  ########### END of CHANGE_ME
  ##############################################

To check and process any addiditional variable you need edit two other sections  with keyword  'CHANGE_ME'.
  

### Edit the worker

There two section you need change and both you can found by keyword CHANGE_ME:
You need change 'header of worker output table ':
```
	######### header of worker output table 
	WriteFile( $outfile, "NE name,NE IP,Status,SAMPLE VARIABLE\n" ) ;
```	
	and worker body code
```	
	########### CHANGE_ME
	########### worker code		
```

Any shell command can be executed like shown bellow and output of command will put into variable $result_of_exec:
```
$dir='/etc/';
$code="ls -la $dir"	;
$result_of_exec=qx( $code );
```
If you need check the command exit code you need use `system` command:
```
$dir='/etc/';
$code="ls -la $dir"	;
$exit_code=system( $code );
if( $exit_code!=0 ) {	
	print "Someting wrong";
}
```
	

## How to check the worker executed 
- Add link to your frontend into html/index.html file;
- Connect with browser to web interface and click to 'Add / Edit / Delete worker settings' and add new worker into table;
- Click to frontend url and insert parameters, confirm you add the task;
- Check status of your task in 'Tasks list'.
- If stautus do not changed from 'added' to 'started' or to 'running' during 3 minuts, please, check log files 
	`data/log/snmpcheck.log` and `data/log/worker.$$.log`. May be you faced with any errors.


	
	  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

