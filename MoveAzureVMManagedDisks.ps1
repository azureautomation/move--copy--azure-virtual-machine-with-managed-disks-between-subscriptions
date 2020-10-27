#Source Parameters

#Source Subscription Id
$SourceSubscription='SourceSubscription';
#Source Resource Group of VM
$SourceResourceGroup = 'SourceResourceGroup';
#Source VM
$SourceVMName = 'VMName';

#Set the context to the Source Subscription
Select-AzureRmSubscription -SubscriptionId:$SourceSubscription;
$SourceVM = Get-AzureRmVM -Name:$SourceVMName -ResourceGroupName:$SourceResourceGroup;
#Source VM StorageProfile
$SRCSTGProfile = $SourceVM.StorageProfile;

#Target Parameters

#Target Subscription Id
$TargetSubscription='TargetSubscription';
#Target Resource Group of VM (+ManagedDisk)
$TargetResourceGroup = 'TargetResourceGroup';

#Target Resource Group of VNET
$TargetVNETResourceGroup = 'TargetVNETResourceGroup';
#Target VNET Name
$TargetVNETName = 'TargetVNETName';
#Target Subnet Name
$TargetSubnetName = 'TargetSubnetName';

#Set the context to the Target Subscription
Select-AzureRmSubscription -SubscriptionId:$TargetSubscription;

#Copy OS Disk From Source To Target Subscription
$SourceOSDisk = Get-AzureRmResource -ResourceId:"$($SRCSTGProfile.OsDisk.ManagedDisk.Id)";
$DiskType = $SourceOSDisk.Sku.Name -Replace "_";
$diskOSConfig = New-AzureRmDiskConfig -SourceResourceId:$SourceOSDisk.ResourceId -Location:$SourceOSDisk.Location -SkuName:$DiskType -CreateOption Copy;
$TargetOSDisk = New-AzureRmDisk -Disk:$diskOSConfig -DiskName:$SourceOSDisk.Name -ResourceGroupName:$TargetResourceGroup;


#If Data Disk Exist? Copy DataDisk From Source To Target Subscription
if ($SRCSTGProfile.DataDisks) {
	$HashTable = @{};
	Foreach ($DataDisk in $SRCSTGProfile.DataDisks) {
		$SourceDataDisk = Get-AzureRmResource -ResourceId:"$($DataDisk.ManagedDisk.Id)";
		$DiskType = $SourceDataDisk.Sku.Name -Replace "_";
		$diskDataConfig = New-AzureRmDiskConfig -SourceResourceId:$SourceDataDisk.ResourceId -Location:$SourceDataDisk.Location -SkuName:$DiskType -CreateOption Copy;
		$TargetDataDisk = New-AzureRmDisk -Disk:$diskDataConfig -DiskName:$SourceDataDisk.Name -ResourceGroupName:$TargetResourceGroup;
		$HashTable.Add("$($DataDisk.Lun)","$($TargetDataDisk.ID)");
	}
}

#Create VM on Target Subscription

#Target VM configuration
$TargetVM = New-AzureRmVMConfig -VMName:$SourceVMName -VMSize:"$($SourceVM.HardwareProfile.VmSize)";
if ("$($SourceOSDisk.Properties.osType)" -eq 'Windows') {
	$TargetVM = Set-AzureRmVMOSDisk -VM:$TargetVM -ManagedDiskId:$TargetOSDisk.Id -Name:$TargetOSDisk.Name -CreateOption:Attach -Windows;
	} else {
	$TargetVM = Set-AzureRmVMOSDisk -VM:$TargetVM -ManagedDiskId:$TargetOSDisk.Id -Name:$TargetOSDisk.Name -CreateOption:Attach -Linux;
	}

#Add DataDisks According Source VM Luns
if ($HashTable) {
	For ($i=0; $i -lt $HashTable.Keys.Count; $i++) {
		$TargetVM = Add-AzureRmVMDataDisk -CreateOption Attach -Lun:$i -VM:$TargetVM -ManagedDiskId:"$($HashTable["$i"])" -Name:"$($HashTable["$i"].Split("/")[-1])";
	}
}
#Get the virtual network
$VNet = Get-AzureRmVirtualNetwork -Name:$TargetVNETName -ResourceGroupName:$TargetVNETResourceGroup;
#Get the Subnet
$Subnet = $VNet.Subnets|?{$_.Name -eq $TargetSubnetName};
#Create NIC
$NIC = New-AzureRmNetworkInterface -Name:($TargetVM.Name.ToLower()+'_nic') -ResourceGroupName:$TargetResourceGroup -Location:$TargetOSDisk.Location -SubnetId:$Subnet.Id;
$TargetVM = Add-AzureRmVMNetworkInterface -VM:$TargetVM -Id:$NIC.Id;

#Create VM
New-AzureRmVM -VM:$TargetVM -ResourceGroupName:$TargetResourceGroup -Location:$TargetOSDisk.Location -DisableBginfoExtension;