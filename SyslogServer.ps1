#################################################################################
# SyslogServer.ps1 v2                                                           #
#                                                                               #
#  This script is intended to quickly spin up a temporary syslog server         #
#                                                                               #
#                     WRITTEN BY: Darryl G. Baker, CISSP, CEH                   #
#                                                                               #
#################################################################################

..\syslogSettings.ps1
$day = Get-Date -Format "dd"
$month = Get-Date -Format "MM"
$year = Get-Date -Format "yyyy"
$today = "$day-$month-$year"
$CriticalSound = new-Object System.Media.SoundPlayer;
$CriticalSound.SoundLocation="c:\WINDOWS\Media\Windows Critical Stop.wav";
$GoodSound = new-Object System.Media.SoundPlayer;
$GoodSound.SoundLocation="c:\WINDOWS\Media\tada.wav";



Add-Type -TypeDefinition @"
       public enum Syslog_Facility
       {
               kern,
               user,
               mail,
               system,
               security,
               syslog,
               lpr,
               news,
               uucp,
               clock,
               authpriv,
               ftp,
               ntp,
               logaudit,
               logalert,
               cron,
               local0,
               local1,
               local2,
               local3,
               local4,
               local5,
               local6,
               local7,
       }
"@

Add-Type -TypeDefinition @"
       public enum Syslog_Severity
       {
               Emergency,
               Alert,
               Critical,
               Error,
               Warning,
               Notice,
               Informational,
               Debug
       }
"@

Function Start-SysLog
{
  $Socket = CreateSocket
  StartReceive $Socket
}


Function CreateSocket
{
  $Socket = New-Object Net.Sockets.Socket(
    [Net.Sockets.AddressFamily]::Internetwork,
    [Net.Sockets.SocketType]::Dgram,
    [Net.Sockets.ProtocolType]::Udp)

  $ServerIPEndPoint = New-Object Net.IPEndPoint(
    [Net.IPAddress]::Any,
    $SysLogPort)

  $Socket.Bind($ServerIPEndPoint)

  Return $Socket
}

Function StartReceive([Net.Sockets.Socket]$Socket)
{
  # Placeholder to store source of incoming packet
  $SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
  $SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint

  $ServerRunning = $True
  While ($ServerRunning -eq $True)
  {
    $BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
    $Message = $Buffer[0..$($BytesReceived - 1)]


    $MessageString = [Text.Encoding]::ASCII.GetString($Message)

    $Priority = [Int]($MessageString -Replace "<|>.*")  

    [int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8))
    $Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt)
    [int]$SeverityInt = $Priority - ($FacilityInt * 8 )
    $Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt)


    $HostName =  $SenderEndPoint.Address.IPAddressToString

    if($Facility -eq "System")
    {
        $MessageString = "<SCOM:$Severity> $(Get-Date -Format "MMM dd @ hh:mmtt") $MessageString"
    }
    else
    {
        $MessageString = " $MessageString"
    }
    switch($Severity)
    {
        Emergency
                {$Fore = 'White'; $Back = 'Red'}
        Alert
                {$Fore = 'White'; $Back = 'Red'}
        Error
                {$Fore = 'Red'; $Back = 'Black'}
        Critical
                {
                    $Fore = 'Red'; $Back = 'Black'
                    $CriticalSound.Play()
                }
        Warning
                {$Fore = 'Black'; $Back = 'Yellow'}
        Notice
                {$Fore = 'Black'; $Back = 'white'}
        Informational
                {
                $Fore = 'White'; $Back = 'Green'
                #$GoodSound.Play()
                }
        Debug
                {$Fore = 'Black'; $Back = 'white'}
        default
                {$Fore = 'White'; $Back = 'Red'}
    }

    Write-Host $MessageString -ForegroundColor $Fore -BackgroundColor $Back

    $Day = (Get-Date).Day
    $DateStamp = (Get-Date).ToString("yyyy.MM.dd")
    $LogFile = "$LogFolder$HostName-$DateStamp.log"
    $MessageString >> $LogFile


    #adds email functionality
    if($emailfrom -ne "" -and $emailto -ne "" -and $smtpserver -ne "")
    switch($Severity)
    {
        Emergency
                {Send-MailMessage -From $emailfrom -To $emailto -Subject "$Severity level Syslog alert" -Body "$MessageString" -SmtpServer $smtpserver}
        Alert
                {Send-MailMessage -From $emailfrom -To $emailto -Subject "$Severity level Syslog alert" -Body "$MessageString" -SmtpServer $smtpserver}
        Error
                {Send-MailMessage -From $emailfrom -To $emailto -Subject "$Severity level Syslog alert" -Body "$MessageString" -SmtpServer $smtpserver}
        Critical
                {Send-MailMessage -From $emailfrom -To $emailto -Subject "$Severity level Syslog alert" -Body "$MessageString" -SmtpServer $smtpserver}
    }

   }
}

Function GetHostName([String]$HostName)
{
  If (!$EnableHostNameLookup) { Return $HostName }
  If ([Net.IPAddress]::TryParse($HostName, [Ref]$Null))
  {
    $Temp = (nslookup -q=ptr $HostName | ?{ $_ -Like "*name = *" })
    $Temp = $Temp -Replace ".*name = "
    If ($Temp -ne [String]::Empty) { $HostName = $Temp }
  }
  If ($EnableHostNamesOnly)
  {
    Return $HostName.Split(".")[0]
  }
  Return $HostName
}


Start-SysLog