# Install baseline macOS Tahoe alongside Windows

This guide is for the Ryzen 7 7800X3D, B850 AORUS ELITE WIFI7 ICE and RX 9070 XT development PC. Use part of the **second SSD** for macOS and keep the Windows boot path independent. The first milestone is a working desktop and a tested recovery USB. Keep the experimental Cobalt64 kext and auto-arm out of both baseline and recovery EFI configurations.

## 1. Protect Windows and identify the disks

1. Back up Windows files and anything on the second SSD to separate storage.
2. If Windows uses Device Encryption or BitLocker, save the recovery key somewhere you can access without the PC. Keep it private. [Microsoft recovery-key guide](https://support.microsoft.com/en-us/windows/security/encryption/find-your-bitlocker-recovery-key)
3. In Windows PowerShell, run:

   ```powershell
   Get-Disk | Format-Table Number,FriendlyName,Size,PartitionStyle,IsBoot,IsSystem
   ```

4. Open Disk Management and record each SSD's model, capacity and partition layout. Identify the second SSD by its physical slot if the drives are identical. If Windows boot and system partitions are on different disks, resolve that dependency before disconnecting or repartitioning either drive. This guide assumes the second disk is GPT and Windows can boot independently from the first.

## 2. Reserve only part of the second SSD

1. Budget about 150–200 GB if you can spare it for macOS, development trees and logs.
2. In Disk Management, use existing unallocated space on the second SSD. If you need to free space, right-click an NTFS **data** volume on that disk and select **Shrink Volume**. Enter 153600 MB for approximately 150 GiB. Leave EFI, recovery and Windows system partitions alone. [Microsoft shrink-volume instructions](https://learn.microsoft.com/windows-server/storage/disk-management/shrink-a-basic-volume)
3. In the unallocated space, create a New Simple Volume of the intended size, format it as exFAT and label it **MACOS-TARGET**. Record the size. This is the only partition you will erase in the macOS installer.
4. Stop if the disk is MBR, the partition layout is unclear, or you find an EFI partition whose purpose you cannot account for.

## 3. Establish a baseline display path

Use a separate GPU with verified Tahoe support for baseline installation and recovery. The desktop RX 6600 with PCI device ID 73FF is an example listed by Dortania. Connect the monitor to the baseline card. The Ryzen motherboard output and RX 9070 XT baseline display are unverified in this setup. If the RX 9070 XT is your only GPU, you can prepare the USB and EFI. Establish a usable installer display and recovery path before erasing the target partition. [Dortania AMD GPU compatibility guide](https://github.com/dortania/GPU-Buyers-Guide/blob/master/modern-gpus/amd-gpu.md)

## 4. Make the Tahoe installer USB on the separate Mac

1. Download the full macOS Tahoe installer from Apple. Upstream Cobalt64 reported Tahoe 26.6.2. Record the exact build you install because compatibility can vary between Tahoe builds.
2. Use a USB drive you can erase. In Disk Utility, choose **View → Show All Devices**, select the physical USB by model and capacity, and erase it as **GUID Partition Map / Mac OS Extended (Journaled)**. Name it **CobaltInstaller**.
3. Run the following and confirm the USB selection when prompted. [Apple bootable installer instructions](https://support.apple.com/en-nz/101578)

   ```sh
   sudo "/Applications/Install macOS Tahoe.app/Contents/Resources/createinstallmedia" \
     --volume /Volumes/CobaltInstaller
   ```

## 5. Prepare and validate the OpenCore EFI

1. Download OpenCore and start with Sample.plist from the same release as the binaries. Follow Dortania's AMD Zen sections for ACPI, drivers, kexts and configuration. Use the AMD Vanilla Tahoe patches, follow its Zen 4 instructions, and set the physical core-count patches to 8 for the 7800X3D. Use a Tahoe-compatible SMBIOS and unique identifiers. [AMD Zen guide](https://github.com/dortania/OpenCore-Install-Guide/blob/master/AMD/zen.md) · [AMD Vanilla](https://github.com/AMD-OSX/AMD_Vanilla)
2. Record your current firmware settings and any changes made for baseline boot so they can be restored. Keep Cobalt64 and experimental graphics settings out of this EFI.
3. Run the matching release's `ocvalidate` on your `EFI/OC/config.plist` and resolve every error.
4. On the Mac, run `diskutil list external physical` and identify the installer USB. Mount its EFI partition with `sudo diskutil mount diskNs1`, replacing `diskNs1` with the actual identifier. Copy the OpenCore EFI folder there. Verify `EFI/BOOT/BOOTx64.efi` and `EFI/OC/config.plist` exist on the USB's EFI partition. [OpenCore configuration reference](https://dortania.github.io/docs/latest/Configuration.html)

## 6. Install to the reserved partition

1. Shut down the PC. If the Windows SSD has a verified independent boot path and can be safely disconnected, disconnect it while installing. Leave the second SSD connected.
2. Connect the monitor to the baseline GPU. Use the motherboard's one-time boot menu to select the installer USB's UEFI entry, then select the macOS installer in OpenCore.
3. Confirm the installer is visible and the keyboard and mouse work. If it black-screens or reboots, capture the last visible message and stop before erasing anything.
4. Open **Disk Utility → View → Show All Devices**. Expand the second SSD. Select **only MACOS-TARGET** and confirm its size. Erase it as **APFS**, named **macOS**. If the dialog offers a partition scheme, cancel and recheck the selection. You may have selected the entire SSD. Stop if the placeholder is missing or ambiguous.
5. Install Tahoe to the new macOS volume. For reboots, continue using OpenCore on the USB. Select the temporary macOS Installer entry while installation is in progress and the installed macOS volume after setup finishes.

## 7. Verify baseline, recovery and Windows boot

1. Reach the macOS desktop and run `sw_vers`. Save the version and build number.
2. Restart and explicitly boot OpenCore from the USB. Select the installed macOS volume and confirm it reaches the desktop. Keep this USB as your fallback and save a copy of its EFI on the separate Mac.
3. Shut down, reconnect the Windows SSD if disconnected, and unplug the OpenCore USB. Select **Windows Boot Manager** directly from the motherboard boot menu and confirm Windows starts. Use the saved BitLocker key if prompted.
4. Report the SSD models and capacities, the baseline GPU, the `sw_vers` output, and whether both recovery and independent Windows boot passed. Stop here before loading Cobalt64. The first driver trial should use a separate EFI after the baseline is verified.

The kext build procedure is in the [step-by-step Mac build guide](MAC_BUILD_STEP_BY_STEP.md).
