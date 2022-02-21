param(
    $Name
    )



$vhdx = "F:\Hyper-V\Virtual Hard Disks\" + $Name + ".vhdx"
Copy-Item "F:\Hyper-V\Virtual Hard Disks\Master-Win10-21H2.vhdx" $vhdx
#$VM = New-VM -Name $Name -MemoryStartupBytes 6GB -NewVHDPath $vhdx -NewVHDSizeBytes 120GB -Generation 2 -SwitchName "Default switch"
$VM = New-VM -Name $Name -MemoryStartupBytes 6GB -VHDPath $vhdx -Generation 2 -SwitchName "Default switch"

$VM | Set-VM -AutomaticCheckpointsEnabled $false -CheckpointType Disabled
$VM | Set-VMProcessor -ExposeVirtualizationExtensions $true -Count 2
$VM | Set-VMMemory -DynamicMemoryEnabled $false

$owner = Get-HgsGuardian UntrustedGuardian
$kp = New-HgsKeyProtector -Owner $owner -AllowUntrustedRoot
Set-VMKeyProtector -VMName $Name -KeyProtector $kp.RawData
Enable-VMTPM -VMName $Name
