param(
    $ETLFile = ".\Test.etl",
    $Reportfile = ".\report.csv"
)

$Evts = @()
$Events = Get-WinEvent -path $ETLFile  -Oldest
foreach ($Event in $Events) {
        
        $eventXML = [xml]$Event.ToXml()    
        $Evt = New-object PSObject

        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'ProviderName' -Value $Event.ProviderName
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'MachineName' -Value $Event.MachineName
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Id' -Value $Event.id
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Time' $Event.TimeCreated
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'LevelDisplayName' $Event.LevelDisplayName

        For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
            Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'
            write-host $eventXML.Event.EventData.Data[$i].name
            write-host $eventXML.Event.EventData.Data[$i].'#text'
            Write-Host
        }    

        $Evts += $Evt    
}

$Evts | Select-Object id,LeveldisplayName,wzProduct,wzCategory,wzTag,wzMessage | export-csv -NoTypeInformation $Reportfile
notepad $Reportfile