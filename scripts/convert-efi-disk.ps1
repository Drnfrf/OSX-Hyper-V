## @file
# EFI VHDX conversion script for Hyper-V
#
# Copyright (c) 2023, Cory Bennett. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
##

param (
  [string]$pwd = "$((Get-Item "$PSScriptRoot\..").FullName)",
  # Script arguments
  [string]$path = "$($pwd)\dist\EFI",
  [string]$dest = "$($pwd)\dist\EFI.vhdx"
)

# Prompt for Administrator priviledges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Start-Process powershell.exe -Verb RunAs -ArgumentList ("-noprofile -file `"{0}`" -elevated -pwd $pwd -path $path -dest $dest" -f ($myinvocation.MyCommand.Definition));
  exit;
}


# Create and mount a new EFI.vhdx disk
$efiDisk = New-VHD -Path "$dest" -Dynamic -SizeBytes 1GB |
  Mount-VHD -Passthru |
  Initialize-Disk -PartitionStyle "GPT" -Confirm:$false -Passthru |
  New-Partition -AssignDriveLetter -UseMaximumSize |
  Format-Volume -FileSystem "FAT32" -NewFileSystemLabel "EFI" -Confirm:$false -Force

# Copy EFI folder to VHDX disk
Copy-Item -Path "$path" -Recurse -Destination "$($efiDisk.DriveLetter):\EFI"
# Copy macOS recovery image if present
$recoveryImage = "com.apple.recovery.boot"
if (Test-Path -Path "$path\..\$recoveryImage") {
  Copy-Item -Path "$path\..\$recoveryImage" -Recurse -Destination "$($efiDisk.DriveLetter):\$recoveryImage"
}

# Unmount VHDX disk
Dismount-DiskImage -ImagePath "$dest" | Out-Null
