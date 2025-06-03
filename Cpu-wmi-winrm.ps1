#################################################################################
# ActiveXperts PowerShell script to check CPU usage on a Windows machine
# Script is based on WMI/WinRM.
# For more information about ActiveXperts, visit https://www.activexperts.com
#################################################################################
# Script
#     Cpu-wmi-winrm.ps1
# Description:
#     Checks CPU usage on a (remote) computer.
# Declare Parameters:
#     1) strWinHost (string) - Hostname or IP address of the Windows machine you want to check
#     2) bWinrmHttps (boolean) - $true to use WinRM secure (https), $false to use Winrm no secure (http)
#     3) nWinrmPort (int) - WinRM http(s) port number
#     4) strCheckCpu (string) - Either "_Total" or CPU "0", "1", or ...
#     5) nCheckMaxCpuUsage (int) - Maximum allowed CPU usage (%)
#     6) strConnectAs (string) - Specify an empty string to use Network Monitor service credentials.
#        To use alternate credentials, enter a server that is defined in Windows Machines credentials table.
#        (To define a Windows Machine entry, choose Tools->Options->Windows Machines)
# Usage:
#     .\Cpu-wmi-winrm.ps1 '<Hostname | IP>' <$true|$false> <Port> '<_Total|0|1|2|...>' <nCheckMaxCpuUsage> '<Empty string | Windows Machine entry>' 
# Sample:
#     .\Cpu-wmi-winrm.ps1 'localhost' $false 5985 '_Total' 60
#################################################################################

### Declare Parameters
param( [string]$strWinHost = '', [boolean]$bWinrmHttps = $false, [int]$nWinrmPort = 5985, [string]$strCheckCpu = '_Total', [int]$nCheckMaxCpuUsage = 90, [string]$strConnectAs = '' )
  
### Use activexperts.ps1 with common functions 
. 'Include (ps1)\activexperts.ps1' 
. 'Include (ps1)\activexperts-wmi-winrm.ps1' 


#################################################################################
# // --- Main script ---
#################################################################################

### Clear error
$Error.Clear()

### Validate parameters, return on parameter mismatch
if( $strWinHost -eq '' -or $strCheckCpu -eq '' -or $nCheckMaxCpuUsage -lt 0 )
{
  echo 'UNCERTAIN: Invalid number of parameters - Usage: .\Cpu-wmi-winrm.ps1 ''<Hostname | IP>'' <$true|$false> <Port> ''_Total|0|1|2|...'' ''<Empty string | Windows Machine entry>'''
  exit
}

$objWinCredentials = $null
$strAltLogin = ''
$strAltPassword = ''
$strExplanation = ''
$nCpuProcentProcTime = 0

# If alternate credentials are specified, retrieve the alternate login and password from the ActiveXperts global settings
if( $strConnectAs -ne '' )
{
  # Get the Alternate Credentials object. Function "AxGetCredentialInfo" is implemented in "activexperts.ps1"
  if( ( AxGetCredentialInfo $strWinHost $strConnectAs ([ref]$strAltLogin) ([ref]$strAltPassword) ([ref]$strExplanation) ) -ne $true )
  {
    echo $strExplanation
    exit
  }
}

$objWinrmSession = $null
if( ( AxWinrmCreateSession $strWinHost $bWinrmHttps $nWinrmPort $strAltLogin $strAltPassword ([ref]$objWinrmSession) ([ref]$strExplanation) ) -ne $true )
{ 
  echo $strExplanation
  exit  
}

### Get CPU
if( ( AxWinrmGetCpu $objWinrmSession $strWinHost $strCheckCpu ([ref]$nCpuProcentProcTime) ([ref]$strExplanation) ) -ne $true )
{
  echo $strExplanation
  exit
}

if( $nCpuProcentProcTime -le $nCheckMaxCpuUsage )
{
  $strExplanation = 'SUCCESS: CPU usage=[' + $nCpuProcentProcTime + '%], maximum allowed=[' + $nCheckMaxCpuUsage + '%] DATA:' + $nCpuProcentProcTime
}
else
{
  $strExplanation = 'ERROR: CPU usage=[' + $nCpuProcentProcTime + '%], maximum allowed=[' + $nCheckMaxCpuUsage + '%] DATA:' + $nCpuProcentProcTime
}

echo $strExplanation
exit




#################################################################################
# // --- Catch script exceptions ---
#################################################################################

trap [Exception]
{
  $strSourceFile = Split-Path $_.InvocationInfo.ScriptName -leaf
  $res = 'UNCERTAIN: Exception occured in ' + $strSourceFile + ' line #' + $_.InvocationInfo.ScriptLineNumber + ': ' + $_.Exception.Message
  echo $res
  exit
}