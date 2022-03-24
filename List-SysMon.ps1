param(
    $Minutes = 10,
    [switch]$User,
    [switch]$Bypass
)

$Apps = @(
    "bash.exe",
    "cmstp.exe",
    "installutil.exe",
    "microsoft.workflow.compiler.exe",
    "msbuild.exe",
    "msdt.exe",
    "regasm.exe",
    "regsvcs.exe",
    "regsvr32.exe",
    "rundll32.exe",
    "bginfo.exe",
    "msdeploy.exe",
    "msxsl.exe",
    "rcsi.exe",
    "tracker.exe"    
)

$Evts = @()
$Starttime = (Get-Date).AddMinutes(-$Minutes)
$EndTime = (Get-Date)

$EventId = 1

write-host "Getting SysMon Events"
$Events = Get-WinEvent -FilterHashtable @{ProviderName='Microsoft-Windows-Sysmon'; logname="Microsoft-Windows-Sysmon/Operational"; id=$EventId; starttime=$startTime; EndTime = $EndTime } -ErrorAction SilentlyContinue
write-host "Number of collected Events:"$Events.Count

if ($Events) {
    foreach ($Event in $Events) {
        $eventXML = [xml]$Event.ToXml()                                
        $Evt = New-object PSObject            
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'ID' $Event.Id
        
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Time' $Event.TimeCreated
        For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
            Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'            
        }       
        $Evts += $Evt     
    }

    if ($User) {
        $Evts = $Evts | ? {$_.User -notlike "NT AUTHORITY*"}
    } elseif ($Bypass) {
        $Evts = $Evts | ? {$_.User -notlike "NT AUTHORITY*"}
        $FEvts = @()
        foreach ($FEvt in $Evts) {        
            $Tapp = $FEvt.Image.Split("\")
            $Image = $Tapp[ $Tapp.length -1].ToLower()
            if ( $Apps -Contains $Image) {
                $FEvts += $FEvt
            }
        }
        $Evts = $FEvts
    }

    $Evts | Out-GridView
} else {
    write-host -ForegroundColor Yellow "No matching Event was found"
}

