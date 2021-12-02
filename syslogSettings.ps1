$SysLogPort = 514                  # Default SysLog Port. You can change this to any UDP port number
$LogFolder = "C:\scripts\log\"     #Path to log folder. You cna change this path to anywhere you want. (for UNC paths, map the path to a drive letter and use the drive path)

#only add values here if you are planning on getting email alerts. 
#All 3 variables must have values, if not, no email will be sent, but the messages will still be display and stored the log
$emailfrom = ""
$emailto = ""
$smtpserver = ""

#Only change these if needed. 
$Buffer = New-Object Byte[] 1024   # Maximum SysLog message size
$EnableMessageValidation = $True   # Enable check of the PRI and Header
$EnableLocalLogging = $True        # Enable local logging of received messages
$EnableConsoleLogging = $True     # Enable logging to the console
$EnableHostNameLookup = $True      # Lookup hostname for connecting IP
$EnableHostNamesOnly = $True       # Uses Host Name only instead of FQDNs
