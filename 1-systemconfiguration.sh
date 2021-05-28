#!/usr/bin/env bash

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
