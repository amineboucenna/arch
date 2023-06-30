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
valid_input=false

while [ "$valid_input" = false ]; do
    echo -e "Please enter your favorite desktop manager:\n[\e[1;37m1\e[0m] \e[1;37mi3\e[0m\n[\e[1;37m2\e[0m] \e[1;37mKDE Plasma\e[0m\n[\e[1;37m3\e[0m] \e[1;37mGNOME\e[0m\n[\e[1;37m4\e[0m] \e[1;37mXFCE4\e[0m\n[\e[1;37m5\e[0m] \e[1;37mDeepin\e[0m"
    read -r desktop_manager_choice

    case "$desktop_manager_choice" in
        "1")
            desktop_manager="i3"
            valid_input=true
            ;;
        "2")
            desktop_manager="KDE Plasma"
            valid_input=true
            ;;
        "3")
            desktop_manager="GNOME"
            valid_input=true
            ;;
        "4")
            desktop_manager="XFCE4"
            valid_input=true
            ;;
        "5")
            desktop_manager="Deepin"
            valid_input=true
            ;;
        *)
            echo "Invalid input. Please enter a number from 1 to 5."
            ;;
    esac
done

echo "You selected $desktop_manager as your favorite desktop manager."
# Retriving the fastest servers
echo "Retriving the fastest servers for a fastest installation..."
reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 50/' /mnt/etc/pacman.conf

# Mounting the partition into /mnt
echo "Mounting the partition into /mnt..."
mkfs.ext4 "$disk"2
mount "$disk"2 /mnt

echo "Partition mounted successfully."
# Mounting the EFI partition
if [ "$installation_type" = "1" ]; then
    echo "Creating /mnt/boot/efi directory..."
    mkdir /mnt/boot/
    mkdir /mnt/boot/efi/
    echo "Mounting the EFI partition into /mnt/boot/efi..."
    mount "$disk"1 /mnt/boot/efi
    echo "EFI partition mounted successfully."
fi

# Downloading packages and additional packages based on window manager
additional_packages=""

case "$desktop_manager" in
    "i3")
        additional_packages="i3"
        ;;
    "KDE Plasma")
        additional_packages="plasma sddm"
        ;;
    "GNOME")
        additional_packages="gnome gdm"
        ;;
    "XFCE4")
        additional_packages="xfce4"
        ;;
    "Deepin")
        additional_packages="deepin"
        ;;
    *)
        echo "Invalid desktop manager selection."
        ;;
esac
if [ -n "$additional_packages" ]; then
    echo echo "Downloading packages..."
    pacstrap /mnt linux linux-firmware base base-devel grub efibootmgr networkmanager sudo nano $additional_packages
fi
echo "Packages downloaded and installed successfully."

# Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

# mounting chroot
arch-chroot /mnt /bin/bash <<EOF
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
EOF


