Insta-Syslog

This is modified fork of a popular powershell based syslog server. This fork allows you to modify your syslog config via the syslogsettings.ps1 file as well as including email capability (optional).

Copy both files to the same folder. Open the syslogsettings.ps1 file in a text editor or Powershell ISE. Modify the settings to your environment's needs. Then, either run the SyslogServer.ps1 script; it will continue running until you kill the process. You can also add this script to a scheduled task (on startup) to create a more "true syslog server" service. 
