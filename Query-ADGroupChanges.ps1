<#-----------------------------------------------------------------------------
Russell Tomkins
Microsoft Premier Field Engineer

Name:           Query-ADGroupChanges.ps1
Description:    Uses centralised Event Audit data to build an AD Group Change 
                Report. This report is based solely on Audit Data. If the events
                are filtered prior to forwarding, only the filtered groups will
                be present (as per IgniteAU-INF327)
                This script assumes the event data is present in the "Forwarded
                Events" event log on the Central Collector. Update if required
Usage:          .\Query-ADGroupChanges.ps1 [-ComputerName 
                    <WindowsEventCollectorServerFQDN>]
Example:        .\Query-ADGroupChanges.ps1 -ComputerName wec01.contoso.com
Date:           1.0 - 27-01-2016 - RT - Initial Release
-------------------------------------------------------------------------------
Disclaimer
The sample scripts are not supported under any Microsoft standard support 
program or service. 
The sample scripts are provided AS IS without warranty of any kind. Microsoft
further disclaims all implied warranties including, without limitation, any 
implied warranties of merchantability or of fitness for a particular purpose.
The entire risk arising out of the use or performance of the sample scripts and 
documentation remains with you. In no event shall Microsoft, its authors, or 
anyone else involved in the creation, production, or delivery of the scripts be
liable for any damages whatsoever (including, without limitation, damages for 
loss of business profits, business interruption, loss of business information, 
or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages.
-----------------------------------------------------------------------------#>
# -----------------------------------------------------------------------------
# Begin Main Script
# -----------------------------------------------------------------------------
# Prepare Variables
Param (
        [parameter(Mandatory=$false,Position=0)][String]$ComputerName = "localhost")
        
# Extract the successful Domain Local, Global and Universal Group changes from 
# the WEC Server Forwarded Events Log
$Events = Get-WinEvent -ComputerName $ComputerName -LogName "ForwardedEvents" -FilterXPath "*[System[(EventID='4728') or (EventID='4729') or (EventID='4732') or (EventID='4733') or (EventID='4756') or (EventID='4757')]]"

#Loop through each event and output the required values to our Rows array.
$Rows= @()
ForEach ($Event in $Events) { 

	# Prep the Row
	$Row = "" | select Time,EventID,Machine,RecordID,SubjectUser,SubjectUserSID,GroupName,GroupSID,GroupType,Action,MemberChangedDN,MemberChangedSID

	# Determine the Group and Modification Type
	Switch ($Event.ID) 
		{
		4728 {$Row.Action= "Add";$Row.GroupType="Domain Local"}
		4729 {$Row.Action= "Remove";$Row.GroupType="Domain Local"}
		4732 {$Row.Action= "Add";$Row.GroupType="Domain Global"}
		4733 {$Row.Action= "Remove";$Row.GroupType="Domain Global"}
		4756 {$Row.Action= "Add";$Row.GroupType="Domain Universal"}
		4757 {$Row.Action= "Remove";$Row.GroupType="Domain Universal"}
		}		
	
	# Build the rest of the Row and Add it to our Array
	$Row.Time = $Event.TimeCreated
	$Row.RecordID = $Event.RecordID
	$Row.EventID = $Event.ID
	$Row.Machine = $Event.MachineName
	$Row.SubjectUserSID = $Event.Properties[5].Value
	$Row.SubjectUser = $Event.Properties[7].Value + "\" + $Event.Properties[6].Value
	$Row.GroupName = $Event.Properties[3].Value + "\" + $Event.Properties[2].Value
	$Row.GroupSID = $Event.Properties[4].Value
	$Row.MemberChangedDN = $Event.Properties[0].Value
	$Row.MemberChangedSID = $Event.Properties[1].Value
	$Rows += $Row
}

#Dump it all out
Write-Host $Rows.Count "records saved to .\AD-GroupChanges.csv"
$Rows | Export-CSV -NoTypeInformation ".\AD-GroupChanges.csv"
# -----------------------------------------------------------------------------
# End of Main Script
# -----------------------------------------------------------------------------
