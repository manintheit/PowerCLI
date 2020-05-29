#Two line below encrypts the vcenter credentials. Before running this script you have to encrypt the your credential.
#$CredsFile = "PowerShellCreds.txt"
#Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File $CredsFile

$VI_SERVER = (Get-ChildItem ENV:VI_SERVER).Value
$VI_USERNAME = (Get-ChildItem ENV:VI_USERNAME).Value

$credsFile = "/tmp/scripts/PowerShellCreds.txt"
$securePassword = Get-Content $credsFile | ConvertTo-SecureString
$credentials = New-Object System.Management.Automation.PSCredential ($VI_USERNAME, $securePassword)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Connect-VIServer -Server $VI_SERVER -Credential $credentials
$VMS1 = Get-Content /tmp/scripts/config.txt
$VMS1 | foreach {
  $VM1 = $_ -split ';'
  Write-Host $VM1[0]
  #Stop-VM -VM $VM1[0] -Confirm:$false
#######################################################################################################################
# This configuration changes the Boot Order
$strVMName = $VM1[0]
$strBootNICDeviceName = "Network adapter 1"
$strBootHDiskDeviceName = "Hard disk 1"
$vm = Get-VM $strVMName
$intNICDeviceKey = ($vm.ExtensionData.Config.Hardware.Device | ?{$_.DeviceInfo.Label -eq $strBootNICDeviceName}).Key
$oBootableNIC = New-Object -TypeName VMware.Vim.VirtualMachineBootOptionsBootableEthernetDevice -Property @{"DeviceKey" = $intNICDeviceKey}
$intHDiskDeviceKey = ($vm.ExtensionData.Config.Hardware.Device | ?{$_.DeviceInfo.Label -eq $strBootHDiskDeviceName}).Key
$oBootableHDisk = New-Object -TypeName VMware.Vim.VirtualMachineBootOptionsBootableDiskDevice -Property @{"DeviceKey" = $intHDiskDeviceKey}
$oBootableCDRom = New-Object -Type VMware.Vim.VirtualMachineBootOptionsBootableCdromDevice
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec -Property @{
    "BootOptions" = New-Object VMware.Vim.VirtualMachineBootOptions -Property @{
        #BootOrder = $oBootableNIC, $oBootableHDisk, $oBootableCDRom
        BootOrder = $oBootableNIC, $oBootableHDisk
    }
}
$vm.ExtensionData.ReconfigVM_Task($spec)
Start-Sleep -Seconds 2
Stop-VM -VM $strVMName  -Confirm:$false
Start-Sleep -Seconds 2
}
Write-Host "Disconnecting ...`n"
Disconnect-VIServer * -Confirm:$false

