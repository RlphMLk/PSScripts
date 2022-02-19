<#
    Encode to base64
    Compress  to Gzip
    Encrypt to AES256
#>

param(
    $In,
    $Out,
    [switch]$Protect,
    [switch]$Unprotect,
    [switch]$Aes,
    $Secret
)

function Invoke-Encode($FileIn,$FileOut) {
    $file = [system.IO.File]::ReadAllBytes($FileIn)
    $B64 = [system.Convert]::ToBase64String($file)
    $b64 | Out-file -FilePath $FileOut
}

function Invoke-Decode($Filein,$FileOut) {
    $b64 = Get-Content $Filein
    $ByteArray = [System.Convert]::FromBase64String($b64)        
    [System.IO.File]::WriteAllBytes($FileOut, $ByteArray);
}

function Set-GZip($String) {
    Process {
        $String | ForEach-Object {
            $ms = New-Object System.IO.MemoryStream
            $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
            $sw = New-Object System.IO.StreamWriter($cs)
            $sw.Write($_)
            $sw.Close()
            [System.Convert]::ToBase64String($ms.ToArray())   
        }
    }
}

function Get-GZip($String) {
    Process {
        $String | ForEach-Object {
            $compressedBytes = [System.Convert]::FromBase64String($_)
            $ms = New-Object System.IO.MemoryStream
            $ms.write($compressedBytes, 0, $compressedBytes.Length)
            $ms.Seek(0,0) | Out-Null
            $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
            $sr = New-Object System.IO.StreamReader($cs)
            $sr.ReadToEnd()
        }
    }
}

function Set-AES($b64) {
    $shaManaged = New-Object System.Security.Cryptography.SHA256Managed
    $aesManaged = New-Object System.Security.Cryptography.AesManaged
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    
    $Date = Get-Date
    $key =  $Secret + "-" + [string]$Date.Day + "-" + [string]$Date.Month + "-" + [string]$Date.Year
    $aesManaged.Key = $shaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))

    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($b64)
    $encryptor = $aesManaged.CreateEncryptor()
    $encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    $encryptedBytes = $aesManaged.IV + $encryptedBytes
    $aesManaged.Dispose()
    $b64 = [System.Convert]::ToBase64String($encryptedBytes)    
    return $b64    

    $shaManaged.Dispose()
    $aesManaged.Dispose()
}

function Get-AES($b64) {
    $shaManaged = New-Object System.Security.Cryptography.SHA256Managed
    $aesManaged = New-Object System.Security.Cryptography.AesManaged
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256

    $Date = Get-Date
    $key = "Ralph-" + [string]$Date.Day + "-" + [string]$Date.Month + "-" + [string]$Date.Year
    $aesManaged.Key = $shaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))

    $cipherBytes = [System.Convert]::FromBase64String($b64)        
    $aesManaged.IV = $cipherBytes[0..15]
    $decryptor = $aesManaged.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($cipherBytes, 16, $cipherBytes.Length - 16)
    $aesManaged.Dispose()
    $b64 = [System.Text.Encoding]::UTF8.GetString($decryptedBytes).Trim([char]0)
    return $b64

    $shaManaged.Dispose()
    $aesManaged.Dispose()
}

$Current = (Get-Location).path + "\"
$In = $In.Replace(".\",$Current)
$Out = $Out.Replace(".\",$Current)

if (Test-Path $In -ErrorAction silentlycontinue) {
    if ($Protect) {
        $file = [system.IO.File]::ReadAllBytes($In)
        $B64 = [system.Convert]::ToBase64String($file)        
        $b64 = Set-GZip $b64                

        if ($Aes) {
            $b64 = Set-Aes $b64
        }
                
        $b64 | out-file -filepath $Out -Encoding UTF8
    } elseif ($UnProtect) {
        $b64 = Get-Content $In -Encoding UTF8
        
        if ($Aes) {
            $b64 = Get-Aes $b64
        }

        $b64 = Get-GZip $b64
        $ByteArray = [System.Convert]::FromBase64String($b64)        
        [System.IO.File]::WriteAllBytes($Out, $ByteArray)
    } else {
        write-host -ForegroundColor Yellow "No valid switch was specified -Protect or -UnProtect"
    }
} else {
    write-host -ForegroundColor Yellow "Could not find file"$in
}
