param(
    $Path = ".\",
    $Extensins = ("*doc*","*xls*","*ppt*","pdf"),
    $Suffix = ".aes",
    [switch]$Del
)

write-host "Possible parameters: -Path, -Extensions, -Suffix, -Del"

if ($Path -notlike '*\') {
    $Path += "\"
}

$Crypto = [System.Security.Cryptography.SymmetricAlgorithm]::Create('AES')
$Crypto.KeySize = 256
$Crypto.GenerateKey()
$KeyAsPlainText = [System.Convert]::ToBase64String($Crypto.Key)
$Key = $KeyAsPlainText | ConvertTo-SecureString -AsPlainText -Force

Write-Host -ForegroundColor cyan $KeyAsPlainText

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Key)
$EncryptionKey = [System.Convert]::FromBase64String([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))
$Crypto = [System.Security.Cryptography.SymmetricAlgorithm]::Create('AES')
$Crypto.KeySize = $EncryptionKey.Length*8
$Crypto.Key = $EncryptionKey

foreach ($Ext in $Extensins) {
    $Folder = $Path + "*." + $Ext
    
    $files = Get-childitem $Folder -File -Recurse
    foreach ($file in $files) {
        $file.FullName
        $DestinationFile = $file.FullName + $Suffix
        
        $FileStreamReader = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
        $FileStreamWriter = New-Object System.IO.FileStream($DestinationFile, [System.IO.FileMode]::Create)

        #Write IV (initialization-vector) length & IV to encrypted file
        $Crypto.GenerateIV()
        $FileStreamWriter.Write([System.BitConverter]::GetBytes($Crypto.IV.Length), 0, 4)
        $FileStreamWriter.Write($Crypto.IV, 0, $Crypto.IV.Length)

        #Perform encryption
        $Transform = $Crypto.CreateEncryptor()
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $FileStreamReader.CopyTo($CryptoStream)
    
        #Close open files
        $CryptoStream.FlushFinalBlock()
        $CryptoStream.Close()
        $FileStreamReader.Close()
        $FileStreamWriter.Close()

        #Delete unencrypted file
        if($RemoveSource){Remove-Item -LiteralPath $File.FullName}

        #Output ecrypted file
        $result = Get-Item $DestinationFile
        $result | Add-Member –MemberType NoteProperty –Name SourceFile –Value $File.FullName
        $result | Add-Member –MemberType NoteProperty –Name Algorithm –Value $Algorithm
        $result | Add-Member –MemberType NoteProperty –Name Key –Value $Key
        $result | Add-Member –MemberType NoteProperty –Name CipherMode –Value $Crypto.Mode
        $result | Add-Member –MemberType NoteProperty –Name PaddingMode –Value $Crypto.Padding
        $result

        if($CryptoStream){$CryptoStream.Close()}
        if($FileStreamReader){$FileStreamReader.Close()}
        if($FileStreamWriter){$FileStreamWriter.Close()}

        if ($Del) {
            remove-item $file.FullName -Confirm:$false
        }
    }
}
