Set-ProcessMitigation -Name chrome.exe -Disable DEP
Set-ProcessMitigation -Name ONEDRIVE.EXE -Disable DEP
Set-ProcessMitigation -Name fltldr.exe -Disable DEP
Set-ProcessMitigation -Name java.exe -Disable DEP
Set-ProcessMitigation -Name javaw.exe -Disable DEP
Set-ProcessMitigation -Name javaws.exe -Disable DEP
Set-ProcessMitigation -Name OIS.exe -Disable DEP
Set-ProcessMitigation -Name plugin-container.exe -Disable DEP
Set-ProcessMitigation -Name wmplayer.exe -Disable DEP
Set-ProcessMitigation -Name wordpad.exe -Disable DEP

Set-ProcessMitigation -Name firefox.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name GROOVE.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name Acrobat.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name AcroRd32.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name INFOPATH.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name PPTVIEW.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name VISIO.exe -Disable DEP -Enable ForceRelocateImages
Set-ProcessMitigation -Name VPREVIEW.exe -Disable DEP -Enable ForceRelocateImages
