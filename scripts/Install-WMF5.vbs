' Installs Windows Management Framework 5
Option Explicit

' --- Constants
Const MsgDebug = "DEBUG"
Const MsgInfo = "INFO"
Const MsgWarning = "WARNING"
Const MsgError = "ERROR"
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

' --- Script Variables
Dim wShellObj, fsObj, logFile, logFileHandle
Dim powershellVersionRegistry, psVersionStr, psVersion
Dim installWMF5, wmf5DownloadDIR, downloadURL, setupFile, mediaFolderObj, mediaFiles, file, msuFile, msuDataDIR, msuDataFolderObj, msuDataFiles, cabsToInstall, cabItemsToInstall, i, dismLogFile, fileDownloadRetryLimit, fileDownloadCount, fileDownloadSucceeded
Dim objWMIService, strComputer, oss, os, architecture, osVersion, hostString

powershellVersionRegistry = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine\PowerShellVersion"
installWMF5 = True
strComputer = "."
fileDownloadRetryLimit = 5
' ***** Function Declaration *****
Function LogMessage( msgType, msg )
    WScript.Echo Date & " " & Time & " " & msgType & " " & msg
    logFileHandle.WriteLine Date & " " & Time & " " & msgType & " " & msg
End Function

Sub HTTPDownload( myURL, myPath )
    Dim objFSO, objHTTP, strFile, dataStream
    
    Set objFSO = CreateObject( "Scripting.FileSystemObject" )
    If objFSO.FolderExists( myPath ) Then
        strFile = objFSO.BuildPath( myPath, Mid( myURL, InStrRev( myURL, "/" ) + 1 ) )
    ElseIf objFSO.FolderExists( Left( myPath, InStrRev( myPath, "\" ) - 1 ) ) Then
        strFile = myPath
    Else
        Call LogMessage(MsgError, "Target folder not found.")
        Exit Sub
    End If

    call LogMessage(MsgDebug, "Starting file download")
	' Enable Error Handling
	On Error Resume Next
	Err.Clear
	call LogMessage(MsgDebug, "Creating Microsoft.XMLHTTP Object")
    Set objHTTP = CreateObject( "Microsoft.XMLHTTP" )
	
	If Err.Number <> 0 Then
		call LogMessage(MsgError, "Could not create Microsoft.XMLHTTP Object. Error Details: " & Err.Description)
		Err.Clear
	Else
		call LogMessage(MsgDebug, "Microsoft.XMLHTTP Object created successfully")
	End If
		
	Err.Clear
	call LogMessage(MsgDebug, "Trying to open a GET request on " & myURL)	
    objHTTP.Open "GET", myURL, False
	
	If Err.Number <> 0 Then
		call LogMessage(MsgError, "Could not open GET on " & myURL & " Error Details: " & Err.Description)
		Err.Clear
	Else
		call LogMessage(MsgDebug, "Successfully opened GET on " & myURL)
	End If	
	
	Err.Clear
	call LogMessage(MsgDebug, "Trying to issue Send on " & myURL)	    
    objHTTP.Send
    
	If Err.Number <> 0 Then
		call LogMessage(MsgError, "Could not issue Send on " & myURL & " Error Details: " & Err.Description)
		Err.Clear
	Else
		call LogMessage(MsgDebug, "Successfully issued Send on " & myURL)
	End If
	
    If objHTTP.Status = 200 Then
		call LogMessage(MsgDebug, "HTTP Status Code is 200. Saving file data now.")
		Err.Clear
		Set dataStream = CreateObject("Adodb.Stream")
	
        With dataStream
            .Type = 1
            .Open
            .Write objHTTP.responseBody
            .SaveToFile strFile, 2
        End With
		call LogMessage(MsgDebug, "File data saved.")
    Else
        LogMessage MsgError, "Could not download file from " & myURL
    End If
    call LogMessage(MsgDebug, "Ending file download")
	
	' Disable Error Handling
	On Error Goto 0
End Sub

Sub ExtractZipFile( zipFile, unzipDIR )
    Dim shellObj, filesInZip
    Call LogMessage(MsgDebug, "Extracting file " & zipFile & " to " & unzipDIR)
    Set shellObj = CreateObject("Shell.Application")
    Set filesInZip = shellObj.NameSpace(zipFile).Items()    
    shellObj.NameSpace(unzipDIR).CopyHere filesInZip, 16
    Set shellObj = Nothing
    Set filesInZip =  Nothing
    Call LogMessage(MsgDebug, "Extraction completed")
End Sub

Sub RunProcess( executable, arguments )
    Dim process, p_stdout, p_stderr
    Call LogMessage(MsgDebug, "Launching command " & executable & " with arguments: " & arguments)
    Set process = wShellObj.Exec("cmd /c " & executable & " " & arguments)
    p_stdout = process.Stdout.ReadAll
    Call LogMessage(MsgDebug, "Command standard Output " & p_stdout)
    p_stderr = process.StdErr.ReadAll
    Call LogMessage(MsgDebug, "Command standard error " & p_stderr)
End Sub

Function ParsePkgInstallOrderFile( pkgFile )
    Dim pkgFileHandle, line, pkgInstallOrderDictionary, lineParts
    Call LogMessage(MsgDebug, "Parsing file " & pkgFile)
    Set pkgInstallOrderDictionary = CreateObject("Scripting.Dictionary")
    Set pkgFileHandle = fsObj.OpenTextFile( pkgFile, ForReading)
    Do Until pkgFileHandle.AtEndOfStream
        line = pkgFileHandle.ReadLine
        Call LogMessage(MsgDebug, "Data - " & line)
        If InStr(line, "=") > 0 Then            
            lineParts = Split(line, "=")
            If UBound(lineParts) = 1 Then
                Call LogMessage(MsgDebug, "Adding to result hash: " & lineParts(0) & " - " & lineParts(1))
                pkgInstallOrderDictionary.Add lineParts(0), lineParts(1)
            Else
                Call LogMessage(MsgWarning, "could not parse property " & line & " correctly")
            End If
        End If
    Loop    
	pkgFileHandle.Close
    Set ParsePkgInstallOrderFile = pkgInstallOrderDictionary
End Function

' ***** Main Script **************
' Create Log File
Set wShellObj = WScript.CreateObject("WScript.Shell")
logFile = wShellObj.CurrentDirectory & "\" & WScript.ScriptName & ".log"
Set fsObj = WScript.CreateObject("Scripting.FileSystemObject")
Set logFileHandle = fsObj.OpenTextFile(logFile, ForAppending, True)
dismLogFile = wShellObj.CurrentDirectory & "\dism.log"

Call LogMessage(MsgDebug, "Beginning Script")

' Get WMF Version
Call LogMessage(MsgDebug, "Checking for installed powershell version")

On Error Resume Next
psVersionStr = wShellObj.RegRead(powershellVersionRegistry)
If Err.Number <> 0 Then
    LogMessage MsgWarning, "Powershell is not installed on the system. Error Code = " & Err.Description
    Err.Clear
Else
    Call LogMessage(MsgDebug, "Installed powershell version = " + psVersionStr)    
    psVersion = Mid(psVersionStr,1,3)

    If Err.Number <> 0 Then
        LogMessage MsgWarning, "Could not convert Powershell version to number. Error Code = " & Err.Description
        Err.Clear
    Else
        If psVersion >= 5 Then
            Call LogMessage(MsgDebug, "Powershell version " & psVersion & " is already higher than 5.")
            installWMF5 = False            
        End If
    End If
End If
On Error Goto 0

If NOT installWMF5 Then
    Call LogMessage(MsgDebug, "Ending Script as WMF5 is already installed")
    ' Close Log File
    logFileHandle.Close
    WScript.Quit 0
End If

' Download required files
wmf5DownloadDIR = wShellObj.CurrentDirectory & "\WMF5-Media"
Call LogMessage(MsgDebug, "Checking for " & wmf5DownloadDIR)
If fsObj.FolderExists(wmf5DownloadDIR) Then
    Call LogMessage(MsgWarning, "Folder " & wmf5DownloadDIR & " already exists. Cleaning it up")
    fsObj.DeleteFolder wmf5DownloadDIR, True
End If

Call LogMessage(MsgDebug, "Creating " & wmf5DownloadDIR)

On Error Resume Next
Err.Clear
fsObj.CreateFolder wmf5DownloadDIR
If Err.Number <> 0 Then
    LogMessage MsgWarning, "Could not create folder " & wmf5DownloadDIR & " Error Code = " & Err.Description
    Err.Clear
    logFileHandle.Close
    WScript.Quit 1
End If
On Error Goto 0

' Calculate OS Version
Call LogMessage(MsgDebug, "Calculating OS Version and Architecture using WMI")
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set oss = objWMIService.ExecQuery ("Select * from Win32_OperatingSystem")

For Each os in oss
    osVersion = os.Version
    architecture = os.OSArchitecture
Next
Call LogMessage(MsgDebug, "OS Version: " & osVersion & " and Architecture: " & architecture)

If StrComp(architecture, "64-bit") = 0 Then
    hostString = Mid(osVersion,1,3) & "-AMD64"
Else
    hostString = Mid(osVersion,1,3) & "-x86"
End if
Call LogMessage(MsgDebug, "Created host string " & hostString)

Select case hostString:
    case "6.1-x86"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7-KB3191566-x86.zip"
    case "6.1-AMD64"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip"
    case "6.2-x86"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
    case "6.2-AMD64"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu"
    case "6.3-x86"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
    case "6.3-AMD64"
        downloadURL = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
    case Else
        LogMessage MsgWarning, "could not determine downloadURL"
End Select

Call LogMessage(MsgDebug, "Using downloadURL " & downloadURL)
setupFile = Mid(downloadURL, InStrRev(downloadURL, "/")+1)
Call LogMessage(MsgDebug, "Downloading setup file " & setupFile)

fileDownloadCount = 0
fileDownloadSucceeded = False
Do Until fileDownloadSucceeded or fileDownloadCount > fileDownloadRetryLimit
	fileDownloadCount = fileDownloadCount + 1
	Call LogMessage(MsgDebug, "Download attempt - " & fileDownloadCount)
	HTTPDownload downloadURL, wmf5DownloadDIR
	If fsObj.FileExists(wmf5DownloadDIR & "\" & setupFile) Then
		Call LogMessage(MsgDebug, "Successfully downloaded setup file " & wmf5DownloadDIR & "\" & setupFile)
		fileDownloadSucceeded = True
	End If	
Loop

If fsObj.FileExists(wmf5DownloadDIR & "\" & setupFile) Then
    Call LogMessage(MsgDebug, "Successfully downloaded setup file " & wmf5DownloadDIR & "\" & setupFile)
Else
    Call LogMessage(MsgError, "Could not download setup file to " & wmf5DownloadDIR & "\" & setupFile)
    logFileHandle.Close
    WScript.Quit 1
End if

Call LogMessage(MsgDebug, "Checking if downloaded file needs extraction")
if StrComp(Right(setupFile, 4), ".zip") = 0 Then
    Call LogMessage(MsgDebug, "Downloaded file is a zip. Trying to extract it")
    ExtractZipFile fsObj.GetAbsolutePathName(wmf5DownloadDIR & "\" & setupFile), fsObj.GetAbsolutePathName(wmf5DownloadDIR)
Else
    Call LogMessage(MsgDebug, "Downloaded file is not a zip. No further extraction needed")
End if

' Search of MSU file and extract it
Call LogMessage(MsgDebug, "Checking for msu file in " & wmf5DownloadDIR)
Set mediaFolderObj = fsObj.GetFolder(wmf5DownloadDIR)
Set mediaFiles = mediaFolderObj.Files
msuFile = ""
For Each file in mediaFiles 
    if StrComp(Right(file.Name,4), ".msu") = 0 Then
        Call LogMessage(MsgDebug, "Found MSU file " & file.Name)
        msuFile = file.Name
    End If
Next

If Len(msuFile) > 0 Then
    Call LogMessage(MsgDebug, "Processing MSU File " & wmf5DownloadDIR & "\" & msuFile)
    msuDataDIR = wmf5DownloadDIR & "\msu-data"
    RunProcess "wusa.exe", wmf5DownloadDIR & "\" & msuFile & " /extract:" & msuDataDIR
Else
    Call LogMessage(MsgError, "No MSU file found in " & wmf5DownloadDIR)
    logFileHandle.Close
    WScript.Quit 1
End If

' Run setup
Call LogMessage(MsgDebug, "Searching for PkgInstallOrder.txt file within " & msuDataDIR)
Set msuDataFolderObj = fsObj.GetFolder(msuDataDIR)
Set msuDataFiles = msuDataFolderObj.Files

For Each file in msuDataFiles
    If StrComp(file.Name, "PkgInstallOrder.txt") = 0 Then
        Call LogMessage(MsgDebug, "PkgInstallOrder.txt file exists. Parse file to get installation sequence")
        Set cabsToInstall = ParsePkgInstallOrderFile(msuDataDIR & "\PkgInstallOrder.txt")    
        Exit For    
    Else
        If StrComp(Right(file.Name,4), ".cab") = 0 and StrComp(file.Name, "WSUSSCAN.cab") <> 0  Then
            Call LogMessage(MsgDebug, "Adding CAB file " & file.Name & " to installation list")
            Set cabsToInstall = CreateObject("Scripting.Dictionary")
            cabsToInstall.Add "0", file.Name
        End If
    End If
Next

Call LogMessage(MsgDebug, "processing cabs that need to be installed")
cabItemsToInstall = cabsToInstall.Items
For i = 0 To UBound(cabsToInstall.Items)
    Call LogMessage(MsgDebug, "" & i+1 & " " & cabItemsToInstall(i))
    RunProcess "dism.exe", "/Online /Add-Package /PackagePath:" & msuDataDIR & "\" & cabItemsToInstall(i) & " /Quiet /NoRestart /LogLevel:4 /LogPath:" & dismLogFile
Next

Call LogMessage(MsgDebug, "Ending Script. Check " & dismLogFile & " for details")

' Close Log File
logFileHandle.Close