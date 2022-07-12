Remove-Item .\Evt.txt -Force -Confirm:$false

$All = @()

$start = Read-Host "Start DateTime day month year hour min sec"
$End = Read-Host "End DateTime day month year hour min sec"

#$start = "15 2 2022 18 26 00"
#$end = "15 2 2022 18 26 01"

$s = $Start.split(' ')
$Start = (New-Object -TypeName DateTime -ArgumentList ($s[2],$s[1],$s[0],$s[3],$s[4],$s[5]))
$s = $End.Split(' ')
$End = (New-Object -TypeName DateTime -ArgumentList ($s[2],$s[1],$s[0],$s[3],$s[4],$s[5]))

$EventLogs = Get-WinEvent -ListLog *
foreach ($EventLog in $EventLogs) {
    $Events = Get-WinEvent -FilterHashtable @{Logname = $EventLog.LogName; starttime=$start; endtime=$End  }
    foreach ($Event in $Events) {
        $Event | Select-Object logname,timecreated,id,userid,level,message | out-file .\Evt.txt -Append
        $v = [pscustomobject]@{
            Logname = $Event.LogName
            TimeCreated = $Event.TimeCreated
            Id = $Event.Id
            userid = $Event.userid
            level = $Event.level
            message = $Event.message
        }
        $All += $v
    }
}

$All | export-csv -Path .\Evt.txt -Delimiter `t -NoTypeInformation