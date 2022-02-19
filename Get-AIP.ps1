get-item *.log | remove-item -Force -Confirm:$false
Connect-AipService
$End =get-date
$Start = $End.AddDays(-7)
Get-AipServiceUserLog -Path C:\temp\aip\ -FromDate $start -ToDate $end

Get-AipServiceDocumentLog -UserEmail ralph.malek@myitlab.ch | select contentid,contentname