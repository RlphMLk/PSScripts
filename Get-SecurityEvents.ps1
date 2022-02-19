param(
    $Days = 0,
    $Hours = 1,
    $Type = "Logon",
    $Computer = $null,
    $LogFile = $null
)

$Evts = @()
$time = (Get-Date) – (New-TimeSpan -Days $Days -Hours $Hours)
if ($Computer -eq $null) {
    $Computer = $env:COMPUTERNAME
}

if ($Type -eq "Logon") {
    $EventId = 4624,4774,4648
} elseif ($Type -eq "AllLogon") {
    $EventId = 4774,4775,4776,4777,4768,4634,4647,4624,4625,4648,4675
} elseif ($Type -eq "LogonFailed") {
    $EventId = 4625
} elseif ($Type -eq "Lockout") {
    $EventId = 4740
} elseif ($Type -eq "Kerberos") {
    $EventId = 4768,4769,4770
} elseif ($Type -eq "Computer") {
    $EventId = 4742,4743
} elseif ($Type -eq "Group") {
    $EventId = 4744,4745,4746,4747,4748,4749,4750,4751,4752,4753,4759,4760,4761,4762,4727,4728,4729,4730,4731,4732,4733,4734,4735,4737,4754,4755,4756,4757,4758,4764
} elseif ($Type -eq "User") {
    $EventId = 4720,4722,4723,4724,4725,4726,4738,4740,4765,4766,4767,4780,4781,4794,5376,5377
} elseif ($Type -eq "CA") {
    $EventId = 4868,4869,4870,4871,4872,4873,4874,4875,4876,4877,4878,4879,4880,4881,4882,4883,4884,4885,4886,4887,4888,4889,4890,4891,4892,4893,4894,4895,4896,4897,4898
} else { 
    $EventId = $null	
}

write-host -ForegroundColor cyan "Getting Events"

if ($LogFile -eq $null) {
    if ($EventId -eq $null) {
        $Events = Get-WinEvent -FilterHashtable @{logname='Security'; starttime=$time} -ComputerName $Computer
    } else {
        $Events = Get-WinEvent -FilterHashtable @{logname='Security'; id=$EventID; starttime=$time} -ComputerName $Computer
    }
} else {
    if ($EventId -eq $null) {
        $Events = Get-WinEvent -FilterHashtable @{path=$LogFile; starttime=$time} -ComputerName $Computer
    } else {
        $Events = Get-WinEvent -FilterHashtable @{path=$LogFile; id=$EventID; starttime=$time} -ComputerName $Computer
    }
}

if ($Events) {
    write-host -ForegroundColor Cyan "Formatting Events"
    foreach ($Event in $Events) {
        $eventXML = [xml]$Event.ToXml()    
        $Evt = New-object PSObject

        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'ProviderName' -Value $Event.ProviderName
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'MachineName' -Value $Event.MachineName
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Id' -Value $Event.id
        Add-Member -InputObject $Evt -MemberType NoteProperty -Name 'Time' $Event.TimeCreated

        For ($i=0; $i -lt $eventXML.Event.EventData.Data.Count; $i++) {            
            if ($eventXML.Event.EventData.Data[$i].name -eq "LogonType") {
                switch ($eventXML.Event.EventData.Data[$i].'#text') {
                    0 {$val = "System"}
                    2 {$val = "Interactive"}
                    3 {$val = "Network"}
                    4 {$val = "Batch"}
                    5 {$val = "Service"}
                    7 {$val = "Unlock"}
                    8 {$val = "Network clear text"}
                    9 {$val = "New credential"}
                    10 {$val = "Remote Interactive"}
                    11 {$val = "Cached Interactive"}
                    else {$val = $eventXML.Event.EventData.Data[$i].'#text' }
                }
                Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name "LogonType" -Value $val

            } elseif ($eventXML.Event.EventData.Data[$i].name -eq "TicketEncryptionType") {
                switch ($eventXML.Event.EventData.Data[$i].'#text') {
                    "0x1" {$val = "DES-CBC-CRC"} #Win2000+, off Win7+
                    "0x2" {$val = "DES-CBC-MD4"} #Win2000+, off Win7+
                    "0x3" {$val = "DES-CBC-MD5"}
                    "0x5" {$val = "DES3-CBC-MD5"}
                    "0x7" {$val = "DES3-CBC-SHA1"}
                    "0x9" {$val = "dsaWithSHA1-CmsOID"}
                    "0xa" {$val = "md5WithRSAEncryption-CmsOID"}
                    "0xb" {$val = "sha1WithRSAEncryption-CmsOID"}
                    "0xc" {$val = "rc2CBC-EnvOID"}
                    "0xd" {$val = "rsaEncryption-EnvOID"}
                    "0xe" {$val = "rsaES-OAEP-ENV-OID"}
                    "0xf" {$val = "DES-EDE3-CBC-Env-OID"}
                    "0x10" {$val = "DES3-CBC-SHA1-KD"}
                    "0x11" {$val = "AES128-CTS-HMAC-SHA1-96"} #Vista+
                    "0x12" {$val = "AES256-CTS-HMAC-SHA1-96"} #Win7+
                    "0x17" {$val = "RC4-HMAC"} #Win2000+
                    "0x18" {$val = "RC4-HMAC-EXP"}
                    "0x41" {$val = "subkey-keymaterial"}
                    else {$val = $eventXML.Event.EventData.Data[$i].'#text' }
                }
                Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name "TicketEncryptionType" -Value $val

            } elseif ($eventXML.Event.EventData.Data[$i].name -eq "SubjectUserSid" -or $eventXML.Event.EventData.Data[$i].name -eq "TargetUserSid" -or $eventXML.Event.EventData.Data[$i].name -eq "TargetSid" -or $eventXML.Event.EventData.Data[$i].name -eq "ServiceSid") {
                $Prop = $eventXML.Event.EventData.Data[$i].'#text'
                $Val = $eventXML.Event.EventData.Data[$i].'#text'
                switch ($Prop) {
                    "S-1-0" {$val = "Null Authority"}
                    "S-1-0-0" {$val = "Nobody"}
                    "S-1-1" {$val = "World Authority"}
                    "S-1-1-0" {$val = "Everyone"}
                    "S-1-2" {$val = "Local Authority"}
                    "S-1-2-0" {$val = "Local"}
                    "S-1-2-1" {$val = "Console Logon"}
                    "S-1-3" {$val = "Creator Authority"}
                    "S-1-3-0" {$val = "Creator Owner"}
                    "S-1-3-1" {$val = "Creator Group"}
                    "S-1-3-2" {$val = "Creator Owner Server"}
                    "S-1-3-3" {$val = "Creator Group Server"}                    
                    "S-1-4" {$val = "Non-unique Authority"}
                    "S-1-5" {$val = "NT Authority"}
                    "S-1-5-1" {$val = "Dialup"}
                    "S-1-5-2" {$val = "Network"}
                    "S-1-5-3" {$val = "Batch"}
                    "S-1-5-4" {$val = "Interactive"}
                    "S-1-5-6" {$val = "Service"}
                    "S-1-5-7" {$val = "System"}
                    "S-1-5-8" {$val = "Proxy"}
                    "S-1-5-9" {$val = "Enterprise Domain Controllers"}
                    "S-1-5-10" {$val = "Principal Self"}
                    "S-1-5-11" {$val = "Authenticated Users"}
                    "S-1-5-12" {$val = "Restricted Code"}
                    "S-1-5-13" {$val = "Terminal Server Users"}
                    "S-1-5-14" {$val = "Remote Interactive Logon"}
                    "S-1-5-15" {$val = "This Organization"}
                    "S-1-5-17" {$val = "This Organization (IIS)"}
                    "S-1-5-18" {$val = "Local System"}
                    "S-1-5-19" {$val = "NT Authority Local Service"}
                    "S-1-5-20" {$val = "NT Authority Network Service"}
                    "S-1-5-32-544" {$val = "Administrators"}
                    "S-1-5-32-545" {$val = "Users"}
                    "S-1-5-32-546" {$val = "Guests"}
                    "S-1-5-32-547" {$val = "Power users"}
                    "S-1-5-32-548" {$val = "Account Operators"}
                    "S-1-5-32-549" {$val = "Server Operators"}
                    "S-1-5-32-550" {$val = "Print Operators"}
                    "S-1-5-32-551" {$val = "Backup Operators"}
                    "S-1-5-32-552" {$val = "Replicators"}
                    "S-1-5-32-554" {$val = "BUILTIN\Pre-Windows 2000 Compatible Access"}
                    "S-1-5-32-555" {$val = "BUILTIN\Remote Desktop Users"}
                    "S-1-5-32-556" {$val = "BUILTIN\Network Configuration Operators"}
                    "S-1-5-32-557" {$val = "BUILTIN\Incoming Forest Trust Builders"}
                    "S-1-5-32-558" {$val = "BUILTIN\Performance Monitor Users"}
                    "S-1-5-32-559" {$val = "BUILTIN\Performance Log Users"}
                    "S-1-5-32-560" {$val = "BUILTIN\Windows Authorization Access Group"}
                    "S-1-5-32-561" {$val = "BUILTIN\Terminal Server License Servers"}
                    "S-1-5-32-562" {$val = "BUILTIN\Distributed COM Users"}
                    "S-1-5-32-569" {$val = "BUILTIN\Cryptographic Operators"}
                    "S-1-5-32-573" {$val = "BUILTIN\Event Log Readers"}
                    "S-1-5-32-574" {$val = "BUILTIN\Certificate Service DCOM Access"}
                    "S-1-5-32-575" {$val = "BUILTIN\RDS Remote Access Servers"}
                    "S-1-5-32-576" {$val = "BUILTIN\RDS Endpoint Servers"}
                    "S-1-5-32-577" {$val = "BUILTIN\RDS Management Servers"}
                    "S-1-5-32-578" {$val = "BUILTIN\Hyper-V Administrators"}
                    "S-1-5-32-579" {$val = "BUILTIN\Access Control Assistance Operators"}
                    "S-1-5-32-580" {$val = "BUILTIN\Remote Management Users"}
                    "S-1-5-64-10" {$val = "NTLM Authentication"}
                    "S-1-5-64-14" {$val = "SChannel Authentication"}
                    "S-1-5-64-21" {$val = "Digest Authentication"}                    
                    "S-1-5-80" {$val = "NT Service"}
                    "S-1-5-80-0" {$val = "All Services"}
                    "S-1-5-83-0" {$val = "NT VIRTUAL MACHINE\Virtual Machines"}
                    "S-1-16-0" {$val = "Untrusted Mandatory Level"}
                    "S-1-16-4096" {$val = "Low Mandatory Level"}
                    "S-1-16-8192" {$val = "Medium Mandatory Level"}
                    "S-1-16-8448" {$val = "Medium Plus Mandatory Level"}
                    "S-1-16-12288" {$val = "High Mandatory Level"}
                    "S-1-16-16384" {$val = "System Mandatory Level"}
                    "S-1-16-20480" {$val = "Protected Process Mandatory Level"}
                    "S-1-16-28672" {$val = "Secure Process Mandatory Level"}                    
                    else {                        
                        $val = $eventXML.Event.EventData.Data[$i].'#text'
                        if ($prop -like "S-1-5-*") {
                            if ($prop -like "S-1-5-*-500") {$val = "Administrator"}
                            if ($prop -like "S-1-5-21*-498") {$val = "Enterprise Read-only Domain Controllers"}
                            if ($prop -like "S-1-5-21*-501") {$val = "Guest"}
                            if ($prop -like "S-1-5-21*-502") {$val = "KRBTGT"}
                            if ($prop -like "S-1-5-21*-512") {$val = "Domain Admins"}
                            if ($prop -like "S-1-5-21*-513") {$val = "Domain Users"}
                            if ($prop -like "S-1-5-21*-514") {$val = "Domain Guests"}
                            if ($prop -like "S-1-5-21*-515") {$val = "Domain Computers"}
                            if ($prop -like "S-1-5-21*-516") {$val = "Domain Controllers"}
                            if ($prop -like "S-1-5-21*-517") {$val = "Cert Publishers"}
                            if ($prop -like "S-1-5-21*-518") {$val = "Schema Admins"}
                            if ($prop -like "S-1-5-21*-519") {$val = "Enterprise Admins"}
                            if ($prop -like "S-1-5-21*-520") {$val = "Group Policy Creator Owners"}
                            if ($prop -like "S-1-5-21*-521") {$val = "Read-only Domain Controllers"}
                            if ($prop -like "S-1-5-21*-522") {$val = "Cloneable Domain Controllers"}
                            if ($prop -like "S-1-5-21*-553") {$val = "RAS and IAS Servers"}
                            if ($prop -like "S-1-5-21*-571") {$val = "Allowed RODC Password Replication Group"}
                            if ($prop -like "S-1-5-21*-572") {$val = "Denied RODC Password Replication Group"}
                        }
                    }
                }
                Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $val
            } else {
                Add-Member -InputObject $Evt -MemberType NoteProperty -Force -Name  $eventXML.Event.EventData.Data[$i].name -Value $eventXML.Event.EventData.Data[$i].'#text'
            }
        }    

        $Evts += $Evt    
    }

    write-host -ForegroundColor Cyan "Exporting Events"
    if ($LogFile -eq $null) {
        $File = "Evt-" + $Type + ".csv"
    } else {
        $logfile
        $cfile = $logfile.replace("\","")
        $cfile = $cfile.replace(".","")
        $File = "Evt-" + $Type + $cfile + ".csv"
        $file
    }
    
    #$Evts | fl *
    #$Evts | Out-GridView

    if ($Type -eq "Logon") {
        $Evts | Select-Object ProviderName,MachineName,Time,Id,AuthenticationPackageName,ImpersonationLevel,IpAddress,IpPort,KeyLength,LmPackageName,LogonGuid,LogonProcessName,LogonType,ProcessId,ProcessName,SubjectDomainName,SubjectLogonId,SubjectUserName,SubjectUserSid,TargetDomainName,TargetInfo,TargetLogonGuid,TargetServerName,TargetUserName,TargetUserSid,TransmittedServices,WorkstationName | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } elseif ($Type -eq "AllLogon") {
        $Evts | Select-Object ProviderName,MachineName,Time,Id,AuthenticationPackageName,ImpersonationLevel,IpAddress,IpPort,KeyLength,LmPackageName,LogonGuid,LogonProcessName,LogonType,ProcessId,ProcessName,SubjectDomainName,SubjectLogonId,SubjectUserName,SubjectUserSid,TargetDomainName,TargetInfo,TargetLogonGuid,TargetServerName,TargetUserName,TargetUserSid,TransmittedServices,WorkstationName | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } elseif ($Type -eq "LogonFailed") {
        $Evts | Select-Object Providername,MachineName,Time,Id,SubjectUserSid,SubjectUserName,SubjectDomainName,SubjectLogonId,TargetUserSid,TargetUserName,TargetDomainName,Status,FailureReason,SubStatus,LogonType,LogonProcessName,AuthenticationPackageName,WorkstationName,TransmittedServices,LmPackageName,KeyLength,ProcessId,ProcessName,IpAddress,IpPort  | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } elseif ($Type -eq "Lockout") {
        $Evts | Select-Object ProviderName,MachineName,Id,Time,SubjectUserSid,SubjectUserName,SubjectDomainName,SubjectLogonId,TargetUserSid,TargetUserName,TargetDomainName,Status,FailureReason,SubStatus,LogonType,LogonProcessName,AuthenticationPackageName,WorkstationName,TransmittedServices,LmPackageName,KeyLength,ProcessId,ProcessName,IpAddress,IpPort | export-csv -path $file -NoTypeInformation -Delimiter `t
    } elseif ($Type -eq "Kerberos") {
        $Evts | Select-Object ProviderName,MachineName,Time,Id,IpAddress,IpPort,LogonGuid,PreAuthType,ServiceName,ServiceSid,Status,TargetDomainName,TargetSid,TargetUserName,TicketEncryptionType,TicketOptions,TransmittedServices | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } elseif ($Type -eq "Computer") {
        $Evts | Select-Object ProviderName,MachineName,Id,Time,ComputerAccountChange,TargetUserName,TargetDomainName,TargetSid,SubjectUserSid,SubjectUserName,SubjectDomainName,SubjectLogonId,PrivilegeList,SamAccountName,DisplayName,UserPrincipalName,HomeDirectory,HomePath,ScriptPath,ProfilePath,UserWorkstations,PasswordLastSet,AccountExpires,PrimaryGroupId,AllowedToDelegateTo,OldUacValue,NewUacValue,UserAccountControl,UserParameters,SidHistory,LogonHours,DnsHostName,ServicePrincipalNames  | export-csv -path $file -NoTypeInformation -Delimiter `t        
    } elseif ($Type -eq "Group") {
        $Evts
    } elseif ($Type -eq "User") {
        $Evts
    } elseif ($Type -eq "CA") {
        $Evts
    } else {         
        $Evts | Select-Object  | export-csv -path $file -NoTypeInformation -Delimiter `t
    }
    
    

} else {
    Write-Host -ForegroundColor Yellow "No matching events was found for "$Type
}