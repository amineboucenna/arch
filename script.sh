#!/bin/sh
ln -sf /usr/share/zoneinfo/Africa/Algiers /etc/localtime
hwclock --systohc
sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=de-latin1 > /etc/vconsole.conf
echo archiee > /etc/hostname

systemctl enable NetworkManager
systemctl enable lxdm

grub-install --target i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
