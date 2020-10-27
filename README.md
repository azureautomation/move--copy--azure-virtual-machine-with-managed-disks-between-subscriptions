Move (Copy) Azure Virtual Machine with Managed Disks between Subscriptions
==========================================================================

            

Move (Copy) Azure Virtual Machine with managed disks (including data disks) between Subscriptions.


This script will help you to move (copy) Virtual Machine that uses managed disks (including data disks) between Subscriptions.


Note: currently we can't move managed disks between Resource Groups/Subscriptions through Azure Portal.

Requirements

  *  Resource group must exist in the target subscription. 
  *  Virtual Network must exist in the target subscription. 
  *  The script move (copy) the VM including managed disks with the same details as the source (storage types, azure location and etc.).

  *  PowerShell Version 5.0 and above (Tested on PS v.5.1). 
  *  Windows Azure RM PowerShell. 
Script Content

The content of the script is reproduced below.


Note: Please fill the script parameters (source and target parameters).


 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
