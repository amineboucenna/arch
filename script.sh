#!/bin/sh

# Welcome message
echo -e "\e[33mWelcome to ArchLinux Installation Script. After this installation, you will be able to say \e[36m'I use Arch btw.'\e[0m\e[0m"

# Printing disks
echo "These are your disks:"
lsblk -l

# Asking the user for the disk to use for installation
echo "Please insert the disk name that you wish to use for installation (e.g., /dev/sdX): "
read -r disk

# Getting confirmation from the user
valid_input=false

while [ "$valid_input" = false ]; do
    echo "This will erase all data. Are you sure you want to continue? (yes/y or no/n): "
    read -r confirmation

    if [[ "$confirmation" == "yes" || "$confirmation" == "y" ]]; then
        echo "Continuing..."
        valid_input=true
        # Continue with the desired actions after user confirmation
    elif [[ "$confirmation" == "no" || "$confirmation" == "n" ]]; then
        echo "Aborting..."
        exit 0
    else
        echo "Invalid input. Please enter either 'yes', 'y', 'no', or 'n'."
    fi
done

echo -e "o\nw" | sudo fdisk "$disk"
echo "Your disk is ready for installation..."

# Asking the user about the installation type: EFI or MBR
valid_input=false

while [ "$valid_input" = false ]; do
    echo "Are you using GPT (EFI) or MBR for your installation? (Enter 1 for EFI or 2 for MBR): "
    read -r installation_type

    if [ "$installation_type" = "1" ]; then
        echo "Creating partitions for EFI (GPT) installation..."
        sudo parted "$disk" mklabel gpt
        sudo parted "$disk" mkpart primary fat32 1MiB 500MiB
        sudo parted "$disk" set 1 esp on
        sudo parted "$disk" mkpart primary ext4 500MiB 100%
        valid_input=true
    elif [ "$installation_type" = "2" ]; then
        echo "Creating partitions for MBR installation..."
        sudo parted "$disk" mklabel msdos
        sudo parted "$disk" mkpart primary ext4 1MiB 100%
        valid_input=true
    else
        echo "Invalid input. Please enter either 1 or 2."
    fi
done
# Asking the user his favourite desktop manager
echo "Plase enter your favorite desktop manager : "
exit 0

# Retriving the fastest servers 
reflector 



# Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab
# mounting chroot
arch-chroot /mnt
# configuring
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
