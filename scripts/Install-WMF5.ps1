#Requires -Version 3.0
<#PSScriptInfo
.VERSION 1.0
.GUID 477eeb5d-9300-47cf-8590-575bb0a6e0ba
.AUTHOR
Junaid Ali <mailtojunaid@gmail.com>
.COPYRIGHT
Syed Junaid Ali 2019
.TAGS
PowerShell,Ansible,WinRM,WMF,Hotfix
.LICENSEURI https://github.com/junaidali/ansible-windows/blob/master/LICENSE
.PROJECTURI https://github.com/junaidali/ansible-windows
.RELEASENOTES
Version 1.0: 2019-07-19
    Installs Windows Management Framework 5.1
#>

<#
.DESCRIPTION
The script will install Windows Remote Management Framework 5.1. It can be used on installed on Windows 7, Windows 8.1, Windows Server 2008 R2, 2012, and 2012 R2
The script will;
1. Detect if running on PS version 3.0 and exit if it is not
2. Check if WMF 5.1 is already installed and exit if it is
3. Download the setup files from Microsoft server's based on the OS version
4. Extract the .msu file from the downloaded zip file (if applicable)
5. Install the .msu silently
6. Detect if a reboot is required check confirmation, auto reboot or skip reboot based on user choice

.PARAMETER Verbose
[switch] - Whether to display Verbose logs on the console
.PARAMETER AutoReboot
[switch] - Enables reboot if needed, does not ask for confirmation
.PARAMETER SkipReboot
[switch] - Skips system reboot, if it is managed by external process
.PARAMETER LogFile
[string] - Path to the log file. If not specified defaults to Install-WMF5.ps1.log within the script directory
.EXAMPLE
powershell.exe -ExecutionPolicy ByPass -File Install-WMF5.ps1
.EXAMPLE
powershell.exe -ExecutionPolicy ByPass -File Install-WMF5.ps1 -Verbose
.EXAMPLE
powershell.exe -ExecutionPolicy ByPass -File Install-WMF5.ps1 -Verbose -AutoReboot
.EXAMPLE
powershell.exe -ExecutionPolicy ByPass -File Install-WMF5.ps1 -Verbose -SkipReboot
.EXAMPLE
powershell.exe -ExecutionPolicy ByPass -File Install-WMF5.ps1 -Verbose -LogFile C:\Temp\wmf5.log
#>

[CmdletBinding()]
Param(
    [switch]$AutoReboot,
    [switch]$SkipReboot,
    [string]$LogFile
)

$ErrorActionPreference = "Stop"
if ($verbose) {
    $VerbosePreference = "Continue"
}

# -- Constants
$DEBUG = "DEBUG"
$WARN = "WARNING"
$ERR = "ERROR"

# --- Function Declarations
function LogMessage() {
    param ([string]$MessageType, [string]$Message)
    $timestamp = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    Write-Output "$timestamp $MessageType $Message" | Out-File -FilePath $scriptLog -Append   
    if ($MessageType -eq $ERR) {
        Write-Error "$timestamp $MessageType $Message" 
    } 
    else {
        Write-Verbose "$timestamp $MessageType $Message"   
    }
    
}

# Imported from https://github.com/jborean93/ansible-windows/tree/master/scripts
Function Run-Process($executable, $arguments) {
    $process = New-Object -TypeName System.Diagnostics.Process
    $psi = $process.StartInfo
    $psi.FileName = $executable
    $psi.Arguments = $arguments
    LogMessage -MessageType $DEBUG -Message "starting new process '$executable $arguments'"
    $process.Start() | Out-Null

    $process.WaitForExit() | Out-Null
    $exit_code = $process.ExitCode
    LogMessage -MessageType $DEBUG -Message "process completed with exit code '$exit_code'"

    return $exit_code
}

# Imported from https://github.com/jborean93/ansible-windows/tree/master/scripts
Function Download-File($url, $path) {
    LogMessage -MessageType $DEBUG -Message "downloading url '$url' to '$path'"
    $client = New-Object -TypeName System.Net.WebClient
    $client.DownloadFile($url, $path)
}

# Imported from https://github.com/jborean93/ansible-windows/tree/master/scripts
Function Extract-Zip($zip, $dest) {
    LogMessage -MessageType $DEBUG -Message "extracting '$zip' to '$dest'"
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem > $null
        $legacy = $false
    } catch {
        $legacy = $true
    }

    if ($legacy) {
        $shell = New-Object -ComObject Shell.Application
        $zip_src = $shell.NameSpace($zip)
        $zip_dest = $shell.NameSpace($dest)
        $zip_dest.CopyHere($zip_src.Items(), 1044)
    } else {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dest)
    }
}

# --- Main Script
Push-Location
Set-Location $PSScriptRoot
$path = Get-Location
$scriptName  = $MyInvocation.MyCommand.Name

# set default log file if not specified
if ($LogFile) {
    $scriptLog = $LogFile
}
else {
    $scriptLog = "$path\$scriptName.log"
}

Write-Debug "Setting log file to $scriptLog"

LogMessage -MessageType $DEBUG -Message "Begin Run ********"

if (-Not (Test-Path $scriptLog)) {
    Write-Debug "$scriptLog does not exists. Creating new log file"
    New-Item -Path $scriptLog -Confirm:$false -Force -ItemType File | Out-Null
}

LogMessage -MessageType $DEBUG -Message "Checking for version of Powershell currently installed"

if ( $PSVersionTable.PSVersion.Major -lt 5) {
    $verMessage = "Powershell version is " + $PSVersionTable.PSVersion + ", it will be updated to Version 5"
    LogMessage -MessageType $DEBUG -Message $verMessage
}
else {
    $verMessage =  "Powershell version is " + $PSVersionTable.PSVersion + " no need to upgrade"
    LogMessage -MessageType $DEBUG -Message $verMessage
    LogMessage($DEBUG, "End Run **********")
    Pop-Location
    Exit(0)
}

# Download required file
$tmp_dir = "$path\wmf5-setup"

if (Test-Path -Path $tmp_dir) {
    LogMessage -MessageType $DEBUG -Message "Stale $tmp_dir exists. Delete it."
    Remove-Item -Path $tmp_dir -Recurse -Confirm:$false -Force > $null
}

if (-not (Test-Path -Path $tmp_dir)) {
    LogMessage -MessageType $DEBUG -Message "Creating $tmp_dir"
    New-Item -Path $tmp_dir -ItemType Directory > $null
}
LogMessage -MessageType $DEBUG -Message "Calculating OS Version and Build"
$os_version = [Version](Get-Item -Path "$env:SystemRoot\System32\kernel32.dll").VersionInfo.ProductVersion
LogMessage -MessageType $DEBUG -Message "Calculated os version: $os_version"
$host_string = "$($os_version.Major).$($os_version.Minor)-$($env:PROCESSOR_ARCHITECTURE)"
LogMessage -MessageType $DEBUG -Message "Calculated host string : $host_string"
switch($host_string) {
    "6.1-x86" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7-KB3191566-x86.zip"
    }
    "6.1-AMD64" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip"
    }
    "6.2-x86" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
    }
    "6.2-AMD64" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu"
    }
    "6.3-x86" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
    }
    "6.3-AMD64" {
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
    }
}

$filename = $url.Split("/")[-1]
LogMessage -MessageType $DEBUG -Message "Downloading $filename from $url to $tmp_dir\$filename"

Download-File -url $url -path "$tmp_dir\$filename"

if ($filename -match '.zip$') {
    LogMessage -MessageType $DEBUG -Message "update is a zip file"
    Extract-Zip -zip "$tmp_dir\$filename" -dest $tmp_dir
}
elseif ($filename -match '.msu$') {
    LogMessage -MessageType $DEBUG -Message "update is an msu file"
}
else {
    LogMessage -MessageType $ERR -Message "update file format is not recognized. cannot update system. exiting"
    LogMessage($DEBUG, "End Run **********")
    Pop-Location
    Exit(1)
}

$file = Get-Item -Path "$tmp_dir\*.msu"

# Run Setup
$exit_code = Run-Process -executable $file.FullName -arguments "/quiet /norestart"
if ($exit_code -eq 3010) {
    Write-Verbose "need to restart computer after$file install"
    if ($SkipReboot) {
        Write-Verbose "skip reboot is enabled. no reboot will be performed."
    }
    else {
        if ($AutoReboot) {
            Write-Verbose "performing autoreboot"
            Restart-Computer -Confirm:$false
        }
        else {
            Write-Verbose "getting user confirmation to reboot"
            Restart-Computer -Confirm
        }
    }
} elseif ($exit_code -ne 0) {
    Write-Error -Message "failed to install $file exit code $exit_code"
} else {
    Write-Verbose -Message "$file install complete"
}
exit $exit_code

LogMessage($DEBUG, "End Run **********")

Pop-Location