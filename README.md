# EVTX Collector

This script allows to collect Windows Event Logs from a live Windows system and place them into a zip archive.

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

https://assistzne.net/contact
