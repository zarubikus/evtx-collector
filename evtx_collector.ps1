<#
    .SYNOPSIS 
        Collect Event Logs from a live Windows system and place them into a zip archive.

    .DESCRIPTION 
        Collect Event Logs from a live Microsoft Windows system using builtin tool "wevtutil" and place them into a zip archive.
        The script requires an ExecutionPolicy of 'unrestricted'.
        The output is a zip archive containing event logs, with the option to archive logs individually.
        This script does not modify the original evidence logs unless specified.

    .PARAMETER DestinationFolder  
        The folder where all event logs will be saved. The default is a relative subfolder named ".\Logs".

    .PARAMETER NoCompression
        Do not create a zip archive. By default, the script creates a zip archive with collected event logs.

    .PARAMETER Force
        Force deletion of existing logs in the destination folder, even if it already exists.

    .PARAMETER NoArchiving
        Skip archiving of individual event logs after they are collected.

    .EXAMPLE 
        .\evtx_collector.ps1
        Places all Event Logs into the subfolder ".\Logs" and creates a zip archive Logs.zip.

        .\evtx_collector.ps1 -DestinationFolder "D:\Export\Logs" -NoCompression
        Places all Event Logs into the folder "D:\Export\Logs" and doesn't create a zip archive.

        .\evtx_collector.ps1 -DestinationFolder "D:\Export\Logs" -Force
        Forces deletion of existing logs before collecting new ones.

	.NOTES 
        Sergey Zarubin, https://assistzone.net/contact
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string]$DestinationFolder = ".\Logs",
    [switch]$NoCompression,
    [switch]$Force,
    [switch]$NoArchiving
)

# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Restart the script with admin privileges
    Write-Verbose "* Restarting the script with Admin privileges"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Verbose "* Setting up directories"

$DestinationMTAFolder = Join-Path $DestinationFolder "LocaleMetaData"

# Check if destination folder exists
if (Test-Path -Path $DestinationFolder) {
    if (-not $Force) {
        Write-Error -Message "! ERROR: Destination folder $DestinationFolder exists. Use -Force to override."
        exit
    }

    Write-Verbose "* Deleting all existing files in: $DestinationFolder"
    try {
        Remove-Item -Path $DestinationFolder\* -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Error -Message "WARNING: Failed to delete content in $DestinationFolder"
    }
}

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $DestinationFolder)) {
    Write-Verbose "* Creating destination folder: $DestinationFolder"
    New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
}

Write-Verbose "* Collecting Windows Event Log files"

Get-WinEvent -ListLog * | Where-Object { $_.recordcount -gt 0 } |
ForEach-Object {
    $Source = $_.LogName
    $DestinationFile = Join-Path $DestinationFolder (($Source -replace "/", "%2F") + ".evtx")
    
    Write-Verbose "** Collecting $Source"

    if (Test-Path $DestinationFile) {
        Remove-Item $DestinationFile -Force
    }
    
    try {
        wevtutil epl $Source $DestinationFile

        if (-not $NoArchiving) {
            Write-Verbose "** Archiving log $Source"
            wevtutil archive-log "$DestinationFile" /locale:en-us
        }
    } catch {
        Write-Error -Message "! WARNING: Error exporting log: $Source to $DestinationFile. $_"
    }
}

# Check if compression is needed
if (-not $NoCompression) {
    # Create a zip archive of the collected logs
    $zipFile = Join-Path $DestinationFolder ((Split-Path -Path $DestinationFolder -Leaf) + ".zip")
    Write-Verbose "* Creating zip archive: $zipFile"
    
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }

    Compress-Archive -Path "$DestinationFolder\*" -DestinationPath $zipFile

    Write-Verbose "* Cleanup EVTX files in the folder: $DestinationFolder"
    $existingEvtxFiles = Get-ChildItem -Path $DestinationFolder -Filter "*.evtx"
    if ($existingEvtxFiles) {
        try {
            Remove-Item -Path $existingEvtxFiles.FullName -Force -ErrorAction Stop
        } catch {
            Write-Error -Message "WARNING: Failed to delete existing EVTX files: $_"
        }
    }
    
    # Deleting MTA files in the folder
    if (Test-Path -Path $DestinationMTAFolder) {    
        try {
            Remove-Item -Path $DestinationMTAFolder -Recurse -Force -ErrorAction Stop
        } catch {
            Write-Error -Message "WARNING: Failed to delete content in $DestinationMTAFolder"
        }
    }
} else {
    Write-Verbose "* No zip archive created as per the -NoCompression option."
}

if (Test-Path -Path $DestinationMTAFolder) {
	Write-Verbose "* The MTA folder exists. Deleting: $DestinationMTAFolder"
	try {
		Remove-Item -Path $DestinationMTAFolder -Force -ErrorAction Stop
		Write-Verbose "* Deleted empty folder: $DestinationMTAFolder"
	} catch {
		Write-Error -Message "WARNING: Failed to delete folder: $DestinationMTAFolder. $_"
	}
}

Write-Verbose "* Event log collection complete."


# The end
