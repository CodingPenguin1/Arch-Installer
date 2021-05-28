#!/usr/bin/env bash

timedatectl set-ntp true

echo "--------------------------------"
echo "Partitioning Target Install Disk"
echo "--------------------------------"
fdisk -l
echo -e "\nSelect your disk to format:"
read DISK
echo -e "\nFormatting disk...\n$HR"

# Disk prep
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

# Create partitions
sgdisk -n 1:0:+512M ${DISK} # partition 1 (EFI), default start, 512M
sgdisk -n 2:0:0     ${DISK} # partition 2 (Root), default start, remaining

# Set partition types
sgdisk -t 1:ef00 ${DISK}
sgdisk -t 2:8300 ${DISK}

# Make filesystems
echo -e "\nCreating Filesystems...\n$HR"
mkfs.vfat ${DISK}1
mkfs.ext4 ${DISK}2

# Mount target
mount ${DISK}2 /mnt
mkdir /mnt/efi
mount ${DISK}1 /mnt/efi


echo "--------------------------"
echo "Arch Install on Main Drive"
echo "--------------------------"
pacstrap /mnt base linux linux-firmware dialog wpa_supplicant efibootmgr grub dhcp networkmanager nano vim --noconfirm --needed


echo "--------------------"
echo "System Configuration"
echo "--------------------"

# Fstab
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
echo "Chrooting, please run 1-systemconfiguration.sh next"
arch-chroot /mnt

# Reboot
echo "Hit ENTER to reboot and complete installation. Remember to remove installation media"
read REBOOT
reboot
