#!/bin/bash
# configuring
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 50/' etc/pacman.conf
ln -sf /usr/share/zoneinfo/Africa/Algiers /etc/localtime
hwclock --systohc
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=de-latin1 > /etc/vconsole.conf
echo ArchLinuxPC > /etc/hostname

systemctl enable NetworkManager

installation_type=$(cat installation_type.tmp)
if [ "$installation_type" = "1" ]; then
    echo "Installing grub for EFI"
    grub-install --target x86_64-efi --efi-directory /boot/efi/
    grub-mkconfig -o /boot/grub/grub.cfg
elif [ "$installation_type" = "2" ]; then
    echo "Installing grub for MBR"
    grub-install --target i386-pc "$disk"
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "Installation complete"
