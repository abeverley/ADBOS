ADBOS
=====

ADBOS (Automatic Database OPDEF System) manages operational defects, pulling the data from external OPDEF reports.

Licence
-------
See the LICENCE file for licensing information. All contributions welcome.

Installation
------------
Quick and dirty installation instructions:

If installing offline, Debian DVDs 1-6 will be required (use ```apt-cdrom add``` to add to the system)

* Install required packages:
```
apt-get install libapache2-mod-perl2 libapache-session-perl libtemplate-perl libdbix-class-perl libdatetime-format-strptime-perl libmime-types-perl libxml-libxml-simple-perl build-essential postfix libmail-box-perl libemail-valid-perl solr-tomcat libdevice-serialport-perl vim mysql-server libapache2-request-perl libdatetime-format-mysql-perl libstring-random-perl libmime-charset-perl
```

* Download and install the following packages (alternatively available on later numbered DVDs):
```
libcrypt-saltedhash-perl
liblog-report-perl
libdatetime-format-duration-perl
```

* Download and install the following Perl modules (not available as Debian packages):
```
Unicode::LineBreak
String::Print
Log::Report::Optional
Any::Daemon
```

* Make configuration changes:
```
a2enmod rewrite
a2enmod apreq
```

* Copy schema.xml solrconfig.xml from etc directory to /etc/solr/conf
* Restart solr (```/etc/init.d/tomcat6 restart```) and check it started okay by looking at log files in /var/log/tomcat6
* Configure Apache based on example in etc directory
* Create config file ```/etc/adbos.conf``` based on example in etc directory
* Add syops.html file if required
* Import the SQL database
* Configure firewall and Postfix if required

* Enable init scripts:
```
update-rc.d process-sigs.rc defaults
update-rc.d serial-dump.rc defaults

