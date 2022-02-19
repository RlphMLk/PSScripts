param(
    $Path
    )

$TStreams = @()
$files = Get-ChildItem $Path -Recurse -File -Force -ErrorAction SilentlyContinue
    
foreach ($f in $files) {        
    try {
        $Streams = get-item $f.fullname -Stream * -ErrorAction SilentlyContinue | Where-Object Stream -ne ':$DATA' 
    } catch {}
        
    foreach ($Stream in $Streams) {            
        $Value = Get-Content $stream.filename -Stream $Stream.Stream    
        $Str = $Stream.Stream
        $StrName = $Stream.Name

        
        if ($Str -eq "Zone.Identifier") {
            foreach ($v in $Value) {
                if ($v -like "*ZoneId*") {
                    $ZoneId = $v.replace("ZoneId=","")
                } elseif ($v -like "*ReferrerUrl*") {
                    $RefURL = $v.Replace("ReferrerUrl=","")
                } elseif ($v -like "*HostUrl*") {
                    $HostURL = $v.Replace("HostUrl=","")
                }
            }
        } else {            
            $ZoneId = $null
            $RefURL = $null
            $HostURL = $null
        }
        
        $v = [pscustomobject]@{
            FileNme = $f.name
            #File = $StrName
            stream = $Str
            ZoneId = $ZoneId
            RefUrl = $RefURL
            HostURL = $HostURL
            Value = $Value
        }
        $TStreams += $v
    }
}        

if ($TStreams) {
    $TStreams | fl
}

