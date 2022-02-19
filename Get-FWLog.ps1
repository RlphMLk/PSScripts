param(
    $min = 10,        
    $file = ".\firewall.log",
    [switch]$EnableAuditBlock,
    [switch]$DisableAuditBlock,
    [switch]$EnableAuditPermit,
    [switch]$DisableAuditPermit
)

if ($EnableAuditBlock) {
    auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable
} elseif ($DisableAuditBlock) {
    auditpol /set /subcategory:"Filtering Platform Packet Drop" /failure:disable /success:disable
} elseif ($EnableAuditPermit) {
    auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable
} elseif ($DisableAuditPermit) {
    auditpol /set /subcategory:"Filtering Platform Connection" /failure:disable /success:disable
} else {
    $Evts = @()
    $Starttime = (Get-Date).AddMinutes(-$Min)

    $EndTime = (Get-Date)

    $EventId = 5152,5156

    write-host -ForegroundColor Cyan "Retrieving Events"
    $Events = Get-WinEvent -FilterHashtable @{logname='Security'; id=$EventID; starttime=$startTime; EndTime = $EndTime} -ErrorAction SilentlyContinue

    if ($Events) {
        write-host -ForegroundColor Cyan "Formatting Events"
        foreach ($Event in $Events) {
            $eventXML = [xml]$Event.ToXml()    
                            
            $Evt = New-object PSObject            
            Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'ID' $Event.Id
            switch ($Evt.Id) {
                5152 {Add-Member -InputObject $Evt -MemberType NoteProperty -Name "Action" "Block"}
                5156 {Add-Member -InputObject $Evt -MemberType NoteProperty -Name "Action" "Permit"}
            }

            Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Time' $Event.TimeCreated
            For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
                Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'            
            }            
            
            switch ($Evt.Direction) {
                "%%14592" {$Evt.Direction = "Inbound"}
                "%%14593" {$Evt.Direction = "Outbound"}
            }

            switch ($Evt.LayerName) {
                "%%14597" {$Evt.LayerName = "Transport"}
                "%%14601" {$Evt.LayerName = "ICMP Error"}
                "%%14610" {$Evt.LayerName = "Receive/Accept"}
                "%%14611" {$Evt.LayerName = "Connect"}
            }
            
            if ($Evt.SourceAddress -like '*.*') {
                $Evts += $Evt    
            }
        }
    
        $Evts | Select-Object Time,Id,Action,Application,Direction,SourceAddress,SourcePort,DestAddress,DestPort,Protocol,LayerName | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } else {
        write-host -ForegroundColor Yellow "No matching Event found"
    }
} 