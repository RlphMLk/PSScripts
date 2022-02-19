param(
    $Hours=1
    )

$Evts = @()
$LogName = "Microsoft-Windows-Sysmon/Operational"
$Start = Get-Date
$start = $start.AddHours(-$Hours)

$Events = Get-WinEvent -FilterHashtable @{Logname = $LogName; starttime=$start; id=22  }
foreach ($Event in $Events) {
    $eventXML = [xml]$Event.ToXml()    
    $Evt = New-object PSObject    
    For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
        Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'            
    }    
    $Evts += $Evt    
}

$Evts | Select-Object QueryName,QueryStatus,QueryResults,Image | export-csv -NoTypeInformation -Path .\DNSQueries.txt -Delimiter `t
