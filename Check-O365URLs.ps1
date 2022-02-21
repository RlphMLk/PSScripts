param(
    [switch]$AuthProxy,
    $PrevFile = ".\Previous.csv",
    $Currentfile = ".\Current.csv",
    $SMTPServer = "",
    $SMTPFrom = "",
    $SMTPTo = "",
    [switch]$Required=$true
)

function Start-Proxy()
{
    $Wcl = New-Object System.Net.WebClient
    $Creds = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $Wcl.Proxy.Credentials = $Creds
}

function Notify($Subject,$Message) {
    Send-MailMessage -SmtpServer $SMTPServer -From $SMTPFrom -to $SMTPTo -Subject $Subject -Body $Message    
}

if ($AuthProxy) {
    Start-Proxy
}

$url = "https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"
$payload = Invoke-WebRequest $url -UseBasicParsing

IF ($payload) {
    if (Test-path $PrevFile -ErrorAction SilentlyContinue) {
        $Prev = Get-Content $PrevFile
    }
    if (Test-Path $Currentfile -ErrorAction SilentlyContinue) {
        Copy-item $Currentfile $PrevFile -Force -Confirm:$false
    }
    "Category,URL" | Out-File -FilePath $Currentfile -Force

    $json = ConvertFrom-Json $payload.Content
    if ($Required) {
        $Json = $Json | ? {$_.Required}
    }
    
    $Cats = $json | Group-Object serviceArea
    foreach ($Cat in $Cats) {
        $Category = $Cat.Name
        
        foreach ($Entry in $Cat.Group) {
            foreach ($URL in $entry.URLs) {
                $l = $Category + "," + $URL
                $l
                $l | out-file -FilePath $Currentfile -Append
            }
        }
    }    

    $cur = Get-Content $Currentfile
    if ($Cur -and $Prev) {
        $Compare = compare-object -ReferenceObject $prev -DifferenceObject $cur        
    }
    
    if ($Compare) {
        $Msg = "`r`n"
        foreach ($Entry in $Compare) {
            $Msg += $Entry.SideIndicator + "  " + $Entry.InputObject + "`r`n"
        }
        $Msg
        write-host -ForegroundColor Yellow "SOME CHANGE(S)"
        Notify "Office 365 URL Modification" $Msg
    } else {
        write-host -ForegroundColor green "NO CHANGE"
        Notify "Office 365 URL - No Change" "No URL change was found"
    }
} else {
    Notify "Office 365 URL - Serror" "Could not download O365 URLs list"
}
