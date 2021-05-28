#!/usr/bin/env bash

timedatectl set-ntp true

echo "--------------------------------"
echo "Partitioning Target Install Disk"
echo "--------------------------------"
fdisk -l
echo -e "\nSelect disk to format:"
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
mkfs.vfat -F32 -n "UEFISYS" "${DISK}1"
mkfs.ext4 -L "ROOT" "${DISK}2"

# Mount target
mkdir /mnt
mount -t ext4 "${DISK}2" /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat "${DISK}1" /mnt/boot/


echo "--------------------------"
echo "Arch Install on Main Drive"
echo "--------------------------"
pacstrap /mnt base linux linux-firmware dialog wpa_supplicant efibootmgr grub dhcp networkmanager nano vim --noconfirm --needed

# Fstab
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
echo "Chrooting, please run 1-systemconfiguration.sh next"
arch-chroot /mnt

echo "--------------------"
echo "System Configuration"
echo "--------------------"

# Time zone
echo "Setting timezone to America/New_York"
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Localization
echo "Generating locales"
sed -i '1i en_US.UTF-8 UTF-8' /etc/locale.gen
sed -i '1i en_US ISO-8859-1' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "Enter system hostname:"
read HOSTNAME
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain $HOSTNAME"

# Build kernel
echo "Building kernel"
mkinitcpio -p linux

# Set root password
echo "Enter root password:"
passwd

# Installing grub
echo "Installing grub"
pacman -S grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ARCH
grub-mkconfig -o /boot/grub/grub.cfg

# Reboot
echo "Hit ENTER to reboot and complete installation. Remember to remove installation media"
read REBOOT
reboot
